import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

interface ReminderData {
    userId: string;
    title: string;
    amount: number;
    category: string;
    type: string;
    dueDate: admin.firestore.Timestamp;
    frequency: string;
    isActive: boolean;
}

interface NotificationData {
    userId: string;
    title: string;
    body: string;
    scheduledFor: admin.firestore.Timestamp;
    sent: boolean;
}

export const checkAndCreateNotifications = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async () => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();

        try {
            const remindersSnapshot = await db
                .collection("reminders")
                .where("isActive", "==", true)
                .where("dueDate", ">=", now)
                .get();

            if (remindersSnapshot.empty) {
                console.log("İşlenecek hatırlatıcı yok");
                return;
            }

            const batch = db.batch();

            for (const doc of remindersSnapshot.docs) {
                const reminderData = doc.data();
                
                // Gerekli alanların varlığını kontrol et
                if (!reminderData.userId || !reminderData.title || 
                    !reminderData.amount || !reminderData.category) {
                    console.error(`Eksik veri: ${doc.id}`);
                    continue;
                }

                const reminder = reminderData as ReminderData;
                
                // Bildirim mesajını oluştur
                const formattedAmount = reminder.amount.toLocaleString("tr-TR");
                const typeEmoji = reminder.type === "Gelir" ? "💰" : "💸";
                const body = 
                    `${typeEmoji} ${reminder.category}\n` + 
                    `${formattedAmount} TL\n` +
                    `${reminder.title}`;
                
                // Yeni bildirim oluştur
                const notificationRef = db.collection("notifications").doc();
                batch.set(notificationRef, {
                    userId: reminder.userId,
                    title: `${reminder.type} Hatırlatıcısı`,
                    body: body,
                    amount: reminder.amount,
                    category: reminder.category,
                    type: reminder.type,
                    scheduledFor: now,
                    sent: false,
                    processed: false,
                    createdAt: now,
                    reminderId: doc.id
                });

                // Hatırlatıcının sonraki tarihini güncelle
                if (reminder.frequency !== "once") {
                    const nextDueDate = calculateNextDueDate(
                        reminder.dueDate.toDate(),
                        reminder.frequency
                    );
                    batch.update(doc.ref, {
                        dueDate: admin.firestore.Timestamp.fromDate(nextDueDate)
                    });
                } else {
                    // Tek seferlik hatırlatıcıyı devre dışı bırak
                    batch.update(doc.ref, { isActive: false });
                }
            }

            await batch.commit();
            console.log(`${remindersSnapshot.size} hatırlatıcı işlendi`);
            return;
        } catch (err) {
            const error = err as Error;
            console.error("Hatırlatıcı işleme hatası:", error.message);
            return;
        }
    });

function calculateNextDueDate(currentDate: Date, frequency: string): Date {
    const nextDate = new Date(currentDate);
    
    switch (frequency) {
        case "daily":
            nextDate.setDate(nextDate.getDate() + 1);
            break;
        case "weekly":
            nextDate.setDate(nextDate.getDate() + 7);
            break;
        case "monthly":
            nextDate.setMonth(nextDate.getMonth() + 1);
            break;
        case "yearly":
            nextDate.setFullYear(nextDate.getFullYear() + 1);
            break;
    }
    
    return nextDate;
}

export const sendNotifications = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async () => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();

        try {
            const snapshot = await db
                .collection("notifications")
                .where("processed", "==", false)
                .where("sent", "==", false)
                .get();

            if (snapshot.empty) {
                return;
            }

            const batch = db.batch();
            const messaging = admin.messaging();

            for (const doc of snapshot.docs) {
                const notification = doc.data() as NotificationData;
                const userDoc = await db
                    .collection("users")
                    .doc(notification.userId)
                    .get();

                const fcmToken = userDoc.data()?.fcmToken;

                if (fcmToken) {
                    try {
                        await messaging.send({
                            token: fcmToken,
                            notification: {
                                title: notification.title,
                                body: notification.body
                            }
                        });

                        batch.update(doc.ref, {
                            sent: true,
                            sentAt: now,
                            processed: true
                        });
                    } catch (err) {
                        const error = err as Error;
                        batch.update(doc.ref, {
                            error: error.message,
                            errorAt: now,
                            processed: true
                        });
                    }
                }
            }

            await batch.commit();
            return;
        } catch (err) {
            const error = err as Error;
            console.error("Gönderim hatası:", error.message);
            return;
        }
    });
