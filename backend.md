# Backend Security & Integration Checklist

This document lists backend changes required before the app ships to production.
The frontend has already been hardened on its side. These are the corresponding backend tasks.

***

## 1. HTTPS — CRITICAL (blocking)

**What:** The current API endpoint is plain HTTP. All chat messages, user religion data, and conversation context are transmitted unencrypted.

**Required:** Set up TLS/SSL on the ALB (AWS Load Balancer).

**Steps:**

1. Request or import an SSL certificate via AWS Certificate Manager (ACM) — free for ALB.
2. Add an HTTPS listener (port 443) to the ALB with the ACM certificate.
3. Add a redirect rule: HTTP 80 → HTTPS 443.
4. Update the `.env` file in the Flutter project: change `BASE_URL` from `http://` to `https://`.
5. Remove the `<domain-config cleartextTrafficPermitted="true">` block from `android/app/src/main/res/xml/network_security_config.xml` once HTTPS is live.

***

## 2. Firebase ID Token Verification — CRITICAL

**What:** The Flutter app now attaches a Firebase ID token to every `/chat` request:

```
Authorization: Bearer <firebase_id_token>
```

**Required:** Verify this token on the backend before processing any request.

**Steps (Python/FastAPI example):**

```Python
import firebase_admin
from firebase_admin import auth, credentials

# Initialize once at startup
cred = credentials.ApplicationDefault()  # or credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

def verify_token(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing token")
    token = authorization.removeprefix("Bearer ")
    try:
        decoded = auth.verify_id_token(token)
        return decoded  # contains uid, email, etc.
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/chat")
async def chat(body: ChatRequest, user=Depends(verify_token)):
    uid = user["uid"]
    # proceed with request, uid available for logging/rate-limiting
    ...
```

**Notes:**

* Anonymous Firebase users also get valid ID tokens — the frontend handles this via `signInAnonymously()`. You don't need to distinguish auth methods.
* Token expiry is 1 hour. The client calls `getIdToken()` which auto-refreshes.
* Install: `pip install firebase-admin`

***

## 3. Rate Limiting

**What:** Without auth token verification, anyone could hit `/chat` freely. Even with auth, users could spam requests.

**Required:** Per-UID rate limiting on `/chat`.

**Recommended:** Slowapi (FastAPI) or Redis-backed counter.

```Python
from slowapi import Limiter

limiter = Limiter(key_func=lambda request: request.state.uid)  # per user, not per IP

@app.post("/chat")
@limiter.limit("20/minute")
async def chat(request: Request, body: ChatRequest, user=Depends(verify_token)):
    request.state.uid = user["uid"]
    ...
```

**Suggested limits:**

* Free tier: 20 requests/minute, 100/day
* Paid tier: 60 requests/minute, unlimited/day

***

## 4. Input Validation

**What:** Frontend already caps messages at 2000 characters, but never trust client-side validation.

**Required:** Validate on backend too.

```Python
class ChatRequest(BaseModel):
    question: str
    religion: str
    context: list = []

    @validator('question')
    def question_not_empty(cls, v):
        v = v.strip()
        if not v:
            raise ValueError('Question cannot be empty')
        if len(v) > 2000:
            raise ValueError('Question too long')
        return v

    @validator('religion')
    def valid_religion(cls, v):
        allowed = {'islam', 'christianity', 'hinduism', 'sikhism'}
        if v.lower() not in allowed:
            raise ValueError('Unknown religion')
        return v.lower()

    @validator('context')
    def cap_context(cls, v):
        # Frontend caps at 20 but double-check server-side
        return v[-20:] if len(v) > 20 else v
```

***

## 5. Firebase App Check (backend enforcement)

**What:** The Flutter app initializes Firebase App Check (Play Integrity on Android, App Attest on iOS). This generates an App Check token for every Firebase SDK call.

**Two-step setup:**

**Step 1 — Firebase Console (required):**

1. Go to Firebase Console → App Check.
2. Register Android app with **Play Integrity** provider.
3. Register iOS app with **App Attest** provider.
4. Enable enforcement for Firestore and Authentication.

**Step 2 — Custom API endpoint (optional):**
If you want App Check on `/chat` too:

```Python
from firebase_admin import app_check

def verify_app_check(x_firebase_appcheck: str = Header(...)):
    try:
        app_check.verify_token(x_firebase_appcheck)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid App Check token")
```

The Flutter app automatically includes `X-Firebase-AppCheck` header — no frontend changes needed.

***

## 6. CORS Configuration

**What:** Lock CORS to prevent web scraping of your API. Mobile apps don't send Origin headers so this primarily protects against browser-based abuse.

```Python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[],  # empty = mobile only, no browser access
    allow_credentials=False,
    allow_methods=["POST"],
    allow_headers=["Content-Type", "Authorization", "X-Firebase-AppCheck"],
)
```

***

## 7. Request Size Limit

**What:** Prevent oversized payloads from hitting your AI pipeline.

```Python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

class MaxBodySize(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        content_length = request.headers.get('content-length')
        if content_length and int(content_length) > 64_000:  # 64KB max
            return Response("Payload too large", status_code=413)
        return await call_next(request)

app.add_middleware(MaxBodySize)
```

***

## 8. Error Response Format

**What:** The Flutter app parses `{"detail": "..."}` from error responses. Keep this consistent — FastAPI does it by default.

```Python
raise HTTPException(status_code=400, detail="Your error message here")
# → {"detail": "Your error message here"}
```

Do not return raw stack traces or internal error details in production responses.

***

## Summary — Priority Order

| # | Task                                    | Priority | Blocking for launch? |
| - | --------------------------------------- | -------- | -------------------- |
| 1 | HTTPS on ALB                            | CRITICAL | Yes                  |
| 2 | Firebase ID token verification          | CRITICAL | Yes                  |
| 3 | Rate limiting per UID                   | HIGH     | Recommended          |
| 4 | Input validation (server-side)          | HIGH     | Recommended          |
| 5 | Firebase App Check activation (Console) | MEDIUM   | No, but do it        |
| 6 | CORS lockdown                           | LOW      | No                   |
| 7 | Request size limit                      | MEDIUM   | No                   |
| 8 | Error response format                   | LOW      | No                   |

