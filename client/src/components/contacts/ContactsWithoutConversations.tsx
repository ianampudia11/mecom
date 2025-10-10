import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from '@/hooks/use-translation';
import { useToast } from '@/hooks/use-toast';
import { ContactAvatar } from '@/components/contacts/ContactAvatar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Contact } from '@shared/schema';
import { useDebounce } from '@/hooks/use-debounce';
import {
  MessageCircle,
  Search,
  Users,
  Loader2,
  Plus
} from 'lucide-react';

interface ContactsWithoutConversationsProps {
  onConversationCreated?: (conversationId: number) => void;
}

export function ContactsWithoutConversations({ onConversationCreated }: ContactsWithoutConversationsProps) {
  const { t } = useTranslation();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [searchQuery, setSearchQuery] = useState('');
  const [isExpanded, setIsExpanded] = useState(false);


  const debouncedSearchQuery = useDebounce(searchQuery, 300);


  const { data: contactsData, isLoading } = useQuery({
    queryKey: ['/api/contacts/without-conversations', debouncedSearchQuery],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (debouncedSearchQuery) params.append('search', debouncedSearchQuery);
      params.append('limit', '20');

      const response = await fetch(`/api/contacts/without-conversations?${params}`);
      if (!response.ok) {
        throw new Error('Failed to fetch contacts');
      }
      return response.json();
    },
    enabled: isExpanded,
    staleTime: 5000, // Reduce cache time for better search responsiveness
    refetchOnWindowFocus: false
  });


  const createConversationMutation = useMutation({
    mutationFn: async (contactId: number) => {
      const response = await fetch(`/api/contacts/${contactId}/create-conversation`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to create conversation');
      }
      
      return response.json();
    },
    onSuccess: (conversation) => {
      toast({
        title: t('contacts.conversation_created', 'Conversation Created'),
        description: t('contacts.conversation_created_desc', 'You can now start messaging this contact.'),
      });
      

      queryClient.invalidateQueries({ queryKey: ['/api/conversations'] });
      queryClient.invalidateQueries({ queryKey: ['/api/contacts/without-conversations'] });
      queryClient.invalidateQueries({ queryKey: ['/api/contacts'] });
      

      if (onConversationCreated) {
        onConversationCreated(conversation.id);
      }
    },
    onError: (error: Error) => {
      toast({
        title: t('contacts.conversation_creation_failed', 'Failed to Create Conversation'),
        description: error.message,
        variant: 'destructive',
      });
    }
  });

  const handleCreateConversation = (contact: Contact) => {
    createConversationMutation.mutate(contact.id);
  };

  const truncateName = (name: string, maxLength: number = 14) => {
    if (name.length <= maxLength) return name;
    return name.substring(0, maxLength) + '...';
  };

  const getChannelTypeDisplay = (identifierType?: string) => {
    switch (identifierType) {
      case 'whatsapp_official':
        return { label: 'WhatsApp Official', color: 'bg-green-100 text-green-800' };
      case 'whatsapp_unofficial':
        return { label: 'WhatsApp', color: 'bg-green-100 text-green-800' };
      case 'messenger':
        return { label: 'Messenger', color: 'bg-blue-100 text-blue-800' };
      case 'instagram':
        return { label: 'Instagram', color: 'bg-pink-100 text-pink-800' };
      case 'telegram':
        return { label: 'Telegram', color: 'bg-sky-100 text-sky-800' };
      default:
        return { label: identifierType || 'Unknown', color: 'bg-gray-100 text-gray-800' };
    }
  };

  const contacts = contactsData?.contacts || [];
  const totalContacts = contactsData?.total || 0;

  if (!isExpanded) {
    return (
      <div className="border-b border-gray-200 bg-white">
        <button
          onClick={() => setIsExpanded(true)}
          className="w-full p-3 sm:p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-gray-500" />
            <span className="text-sm font-medium text-gray-700">
              {t('contacts.start_new_conversations', 'Start New Conversations')}
            </span>
            {totalContacts > 0 && (
              <Badge variant="secondary" className="text-xs">
                {totalContacts}
              </Badge>
            )}
          </div>
          <Plus className="h-4 w-4 text-gray-400" />
        </button>
      </div>
    );
  }

  return (
    <div className="border-b border-gray-200 bg-white">
      <div className="p-3 sm:p-4 border-b border-gray-100">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-gray-500" />
            <span className="text-sm font-medium text-gray-700">
              {t('contacts.start_new_conversations', 'Start New Conversations')}
            </span>
            {totalContacts > 0 && (
              <Badge variant="secondary" className="text-xs">
                {totalContacts}
              </Badge>
            )}
          </div>
          <button
            onClick={() => setIsExpanded(false)}
            className="p-1 rounded hover:bg-gray-100"
          >
            <Plus className="h-4 w-4 text-gray-400 rotate-45" />
          </button>
        </div>
        
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            placeholder={t('contacts.search_contacts', 'Search contacts...')}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 pr-8 text-sm"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-2 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <Plus className="h-4 w-4 rotate-45" />
            </button>
          )}
        </div>
      </div>

      <ScrollArea className="max-h-64 overflow-y-auto">
        <div className="max-h-64 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100 hover:scrollbar-thumb-gray-400">
          {isLoading ? (
            <div className="p-4 space-y-3">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="flex items-center gap-3 animate-pulse">
                  <div className="w-10 h-10 bg-gray-200 rounded-full"></div>
                  <div className="flex-1">
                    <div className="h-4 bg-gray-200 rounded w-3/4 mb-1"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </div>
                  <div className="w-16 h-6 bg-gray-200 rounded"></div>
                </div>
              ))}
            </div>
          ) : contacts.length === 0 ? (
            <div className="p-4 text-center text-gray-500">
              <div className="text-sm">
                {debouncedSearchQuery
                  ? t('contacts.no_contacts_found', 'No contacts found')
                  : t('contacts.all_contacts_have_conversations', 'All contacts already have conversations')
                }
              </div>
            </div>
          ) : (
            <div className="p-2">
              {contacts.map((contact: Contact) => {
                const channelInfo = getChannelTypeDisplay(contact.identifierType || undefined);
                const isCreating = createConversationMutation.isPending;

                return (
                  <div
                    key={contact.id}
                    className="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <ContactAvatar
                      contact={contact}
                      size="sm"
                      showRefreshButton={false}
                    />

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-medium text-gray-900 truncate">
                          {truncateName(contact.name)}
                        </p>
                        <Badge
                          variant="secondary"
                          className={`text-xs ${channelInfo.color}`}
                        >
                          {channelInfo.label}
                        </Badge>
                      </div>
                      <p className="text-xs text-gray-500 truncate">
                        {contact.phone || contact.email}
                      </p>
                    </div>

                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleCreateConversation(contact)}
                      disabled={isCreating}
                      className="flex-shrink-0"
                    >
                      {isCreating ? (
                        <Loader2 className="h-3 w-3 animate-spin" />
                      ) : (
                        <MessageCircle className="h-3 w-3" />
                      )}
                    </Button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  );
}
