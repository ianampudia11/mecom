import { Dialog, DialogContent, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { VisuallyHidden } from "@radix-ui/react-visually-hidden";
import ConversationView from "./ConversationView";
import { useConversations } from "@/context/ConversationContext";
import { useEffect } from "react";

interface QuickChatModalProps {
    isOpen: boolean;
    onClose: () => void;
    contactId?: number;
    dealId?: number;
    conversationId?: number;
}

export default function QuickChatModal({ isOpen, onClose, contactId, conversationId }: QuickChatModalProps) {
    const { setActiveConversationId, conversations, pendingNewConversationContactId, setPendingNewConversationContactId } = useConversations();

    useEffect(() => {
        if (isOpen) {
            if (conversationId) {
                setActiveConversationId(conversationId);
            } else if (contactId) {
                // Find existing conversation with this contact
                const existingConv = conversations.find(c => c.contactId === contactId);
                if (existingConv) {
                    setActiveConversationId(existingConv.id);
                } else {
                    // Trigger new conversation flow in Context if supported, or handle gracefully
                    // The context has `pendingNewConversationContactId` which ConversationView/List usually handles.
                    // But here we are just showing the View.
                    // If we don't have a conversation, ConversationView shows "No Conversation Selected" or similar.
                    // we might need to trigger creation or selection logic detailed in Context.
                    setPendingNewConversationContactId(contactId);
                }
            }
        } else {
            // Optional: clear active conversation on close? 
            // Better to leave it or clear it depending on UX. 
            // Accessing "Inbox" later might show weird state if we don't clear or reset.
            setActiveConversationId(null);
        }
    }, [isOpen, contactId, conversationId, conversations, setActiveConversationId, setPendingNewConversationContactId]);

    return (
        <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="max-w-4xl h-[80vh] p-0 flex flex-col gap-0 overflow-hidden">
                <VisuallyHidden>
                    <DialogTitle>Quick Chat</DialogTitle>
                    <DialogDescription>Chat with the contact associated with this deal.</DialogDescription>
                </VisuallyHidden>
                <div className="flex-1 min-h-0 relative w-full flex flex-col h-full">
                    <ConversationView />
                </div>
            </DialogContent>
        </Dialog>
    );
}
