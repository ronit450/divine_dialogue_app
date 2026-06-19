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
    // YYYY-MM-DD in UTC — used to gate one notification per plan per day.
    const today = now.toISOString().slice(0, 10);

    const usersSnap = await db.collection('users').get();

    let sentCount = 0;

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

        await Promise.all(
          plansSnap.docs.map(async (planDoc) => {
            const plan = planDoc.data();

            // Match hour; allow ±5 minute window to absorb scheduling drift.
            if (plan.reminderHour !== currentHour) return;
            if (Math.abs((plan.reminderMinute ?? 0) - currentMinute) > 5) return;

            // Hard guard: skip if this plan already fired a notification today.
            if (plan.lastNotifiedDate === today) return;

            const dayNum: number = plan.dayNumber ?? 1;
            const duration: number | null = plan.durationDays ?? null;
            const units: number = plan.unitsPerDay ?? 1;
            const label: string = plan.unitLabel ?? 'page';
            const mins: number = plan.estimatedMinutesPerDay ?? 5;

            const bodyDay = duration != null
              ? `Day ${dayNum} of ${duration}`
              : `Day ${dayNum}`;

            try {
              await messaging.send({
                token: fcmToken,
                notification: {
                  title: `A few minutes with ${plan.textTitle ?? 'your reading'}?`,
                  body: `${bodyDay} · ${units} ${label}, ~${mins} min`,
                },
                android: { priority: 'high' },
                apns: { payload: { aps: { sound: 'default', badge: 1 } } },
              });

              // Mark this plan as notified today so re-runs don't double-fire.
              await planDoc.ref.update({ lastNotifiedDate: today });
              sentCount++;
            } catch (err) {
              // Log but don't throw — one bad token shouldn't block others.
              console.warn(
                `FCM send failed for token ...${fcmToken.slice(-6)}: ${err}`
              );
            }
          })
        );
      })
    );

    console.log(`sendReadingReminders: sent ${sentCount} notification(s).`);
  }
);
