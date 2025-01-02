import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onBudgetInvitation = functions.firestore
    .document('budgetInvitations/{invitationId}')
    .onCreate(async (snap, context) => {
        const invitation = snap.data();
        
        // Email gönderme işlemi
        // Burada bir email servisi kullanılabilir
        console.log(`Invitation created for ${invitation.email}`);
    }); 