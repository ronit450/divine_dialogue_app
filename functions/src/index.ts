import { onSchedule } from 'firebase-functions/v2/scheduler';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp();

/**
 * Runs every hour (UTC). Queries users whose reading plan reminder time
 * falls within the current hour, then sends FCM push notifications.
 *
 * Deploy: firebase deploy --only functions
 * Requires: Firebase Blaze (pay-as-you-go) plan for scheduled functions.
 */
export const sendReadingReminders = onSchedule(
  {
    schedule: 'every 60 minutes',
    timeZone: 'UTC',
    region: 'us-central1',
  },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();

    const now = new Date();
    const currentHour = now.getUTCHours();
    const currentMinute = now.getUTCMinutes();

    const sends: Array<{ token: string; title: string; body: string }> = [];

    const usersSnap = await db.collection('users').get();

    await Promise.all(
      usersSnap.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        const fcmToken: string | undefined = userData.fcmToken;
        if (!fcmToken) return;

        const plansSnap = await db
          .collection('users')
          .doc(userDoc.id)
          .collection('readingPlans')
          .where('reminderEnabled', '==', true)
          .get();

        for (const planDoc of plansSnap.docs) {
          const plan = planDoc.data();

          // Match hour; allow ±5 minute window to absorb scheduling drift.
          if (plan.reminderHour !== currentHour) continue;
          if (Math.abs((plan.reminderMinute ?? 0) - currentMinute) > 5) continue;

          const dayNum: number = plan.dayNumber ?? 1;
          const duration: number | null = plan.durationDays ?? null;
          const units: number = plan.unitsPerDay ?? 1;
          const label: string = plan.unitLabel ?? 'page';
          const mins: number = plan.estimatedMinutesPerDay ?? 5;

          const bodyDay = duration != null
            ? `Day ${dayNum} of ${duration}`
            : `Day ${dayNum}`;

          sends.push({
            token: fcmToken,
            title: `A few minutes with ${plan.textTitle ?? 'your reading'}?`,
            body: `${bodyDay} · ${units} ${label}, ~${mins} min`,
          });
        }
      })
    );

    if (sends.length === 0) return;

    // Send individually so each user gets their own personalised message.
    await Promise.all(
      sends.map((s) =>
        messaging
          .send({
            token: s.token,
            notification: { title: s.title, body: s.body },
            android: { priority: 'high' },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          })
          .catch((err) => {
            // Log but don't throw — one bad token shouldn't block others.
            console.warn(
              `FCM send failed for token ...${s.token.slice(-6)}: ${err}`
            );
          })
      )
    );

    console.log(`sendReadingReminders: sent ${sends.length} notification(s).`);
  }
);
