"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendReadingReminders = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
(0, app_1.initializeApp)();
/**
 * Runs every hour (UTC). Queries users whose reading plan reminder time
 * falls within the current hour, then sends FCM push notifications.
 *
 * Deploy: firebase deploy --only functions
 * Requires: Firebase Blaze (pay-as-you-go) plan for scheduled functions.
 */
exports.sendReadingReminders = (0, scheduler_1.onSchedule)({
    schedule: 'every 60 minutes',
    timeZone: 'UTC',
    region: 'us-central1',
}, async () => {
    const db = (0, firestore_1.getFirestore)();
    const messaging = (0, messaging_1.getMessaging)();
    const now = new Date();
    const currentHour = now.getUTCHours();
    const currentMinute = now.getUTCMinutes();
    // YYYY-MM-DD in UTC — used to gate one notification per plan per day.
    const today = now.toISOString().slice(0, 10);
    // Requires index: users collection, fcmToken ASC (create in Firebase Console if missing)
    const usersSnap = await db.collection('users')
        .where('fcmToken', '!=', null)
        .get();
    let sentCount = 0;
    await Promise.all(usersSnap.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        if (!fcmToken)
            return;
        const plansSnap = await db
            .collection('users')
            .doc(userDoc.id)
            .collection('readingPlans')
            .where('reminderEnabled', '==', true)
            .get();
        await Promise.all(plansSnap.docs.map(async (planDoc) => {
            var _a, _b, _c, _d, _e, _f, _g;
            const plan = planDoc.data();
            // Match hour; allow ±5 minute window to absorb scheduling drift.
            if (plan.reminderHour !== currentHour)
                return;
            if (Math.abs(((_a = plan.reminderMinute) !== null && _a !== void 0 ? _a : 0) - currentMinute) > 5)
                return;
            // Hard guard: skip if this plan already fired a notification today.
            if (plan.lastNotifiedDate === today)
                return;
            const dayNum = (_b = plan.dayNumber) !== null && _b !== void 0 ? _b : 1;
            const duration = (_c = plan.durationDays) !== null && _c !== void 0 ? _c : null;
            const units = (_d = plan.unitsPerDay) !== null && _d !== void 0 ? _d : 1;
            const label = (_e = plan.unitLabel) !== null && _e !== void 0 ? _e : 'page';
            const mins = (_f = plan.estimatedMinutesPerDay) !== null && _f !== void 0 ? _f : 5;
            const bodyDay = duration != null
                ? `Day ${dayNum} of ${duration}`
                : `Day ${dayNum}`;
            try {
                await messaging.send({
                    token: fcmToken,
                    notification: {
                        title: `A few minutes with ${(_g = plan.textTitle) !== null && _g !== void 0 ? _g : 'your reading'}?`,
                        body: `${bodyDay} · ${units} ${label}, ~${mins} min`,
                    },
                    android: { priority: 'high' },
                    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
                });
                // Mark this plan as notified today so re-runs don't double-fire.
                await planDoc.ref.update({ lastNotifiedDate: today });
                sentCount++;
            }
            catch (err) {
                // Log but don't throw — one bad token shouldn't block others.
                console.warn(`FCM send failed for token ...${fcmToken.slice(-6)}: ${err}`);
            }
        }));
    }));
    console.log(`sendReadingReminders: sent ${sentCount} notification(s).`);
});
//# sourceMappingURL=index.js.map