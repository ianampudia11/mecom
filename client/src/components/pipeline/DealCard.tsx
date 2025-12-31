import { useState } from 'react';
import { useMutation, useQueryClient, useQuery } from '@tanstack/react-query';
import { formatDistanceToNow } from 'date-fns';
import { MoreHorizontal, User, Clock, Calendar, Tag, AlertCircle, ArrowUp, ArrowRight, ArrowDown, CheckCircle2, MessageSquare, Home, MessageCircle } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';
import HighlightedText from '@/components/ui/highlighted-text';
import { Deal } from '@shared/schema';
import { apiRequest } from '@/lib/queryClient';
import { useLocation } from 'wouter';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Badge } from '@/components/ui/badge';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { ContactAvatar } from '@/components/contacts/ContactAvatar';
import { ColoredTag } from '@/components/ui/colored-tag';
import EditDealModal from './EditDealModal';
import DealDetailsModal from './DealDetailsModal';
import ContactDetailsModal from './ContactDetailsModal';

// Extend Deal type to include the fields we added in the backend
interface ExtendedDeal extends Deal {
  contact?: {
    name: string | null;
    phone: string | null;
    email: string | null;
  };
  propertyCount?: number;
}

interface DealCardProps {
  deal: ExtendedDeal;
  isSelected?: boolean;
  onSelect?: (deal: Deal, selected: boolean) => void;
  showSelectionMode?: boolean;
  searchTerm?: string;
  pipelineId?: number;
}

export default function DealCard({
  deal,
  isSelected = false,
  onSelect,
  showSelectionMode = false,
  searchTerm = '',
  pipelineId
}: DealCardProps) {

  const queryClient = useQueryClient();
  const [, setLocation] = useLocation();
  const { toast } = useToast();
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [isEditDealModalOpen, setIsEditDealModalOpen] = useState(false);
  const [isDealDetailsModalOpen, setIsDealDetailsModalOpen] = useState(false);
  const [isContactDetailsModalOpen, setIsContactDetailsModalOpen] = useState(false);

  // Use embedded contact or fetch if missing (fallback for legacy/other views)
  const { data: fetchedContact } = useQuery({
    queryKey: ['/api/contacts', deal.contactId],
    queryFn: () => apiRequest('GET', `/api/contacts/${deal.contactId}`)
      .then(res => res.json()),
    enabled: !!deal.contactId && !deal.contact, // Only fetch if we don't have it
  });

  const contact = deal.contact || fetchedContact;

  const { data: teamMembers = [] } = useQuery({
    queryKey: ['/api/team-members'],
    queryFn: () => apiRequest('GET', '/api/team-members')
      .then(res => res.json()),
  });

  const assignedUser = teamMembers.find((member: any) => member.id === deal.assignedToUserId);

  // Fetch tag colors
  const { data: tagStats = [] } = useQuery({
    queryKey: ['/api/tags/stats'],
    queryFn: () => apiRequest('GET', '/api/tags/stats')
      .then(res => res.json()),
  });

  // Create a map of tag colors
  const tagColorsMap = new Map(
    tagStats.map((tagStat: any) => [tagStat.tag, tagStat.color])
  );

  // Fetch checklists for checklist progress
  const { data: checklists = [] } = useQuery({
    queryKey: [`/api/deals/${deal.id}/checklists`],
    queryFn: () => apiRequest('GET', `/api/deals/${deal.id}/checklists`)
      .then(res => res.json()),
    enabled: !!deal.id,
  });

  // Calculate checklist progress
  // Fetch linked properties if count > 0
  const { data: linkedProperties = [] } = useQuery({
    queryKey: ['/api/deals', deal.id, 'properties'],
    queryFn: () => apiRequest('GET', `/api/deals/${deal.id}/properties`).then(res => res.json()),
    enabled: !!deal.id && (deal.propertyCount || 0) > 0,
  });

  const getChecklistProgress = () => {
    const allItems = checklists.flatMap((checklist: any) => checklist.items || []);
    if (allItems.length === 0) return { completed: 0, total: 0 };
    const completed = allItems.filter((item: any) => item.isCompleted).length;
    return { completed, total: allItems.length };
  };

  const checklistProgress = getChecklistProgress();

  // Fetch comments for comment count
  const { data: comments = [] } = useQuery({
    queryKey: [`/api/deals/${deal.id}/comments`],
    queryFn: () => apiRequest('GET', `/api/deals/${deal.id}/comments`)
      .then(res => res.json()),
    enabled: !!deal.id,
  });

  const commentCount = comments.length;

  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await apiRequest('DELETE', `/api/deals/${id}`);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/deals'] });

      if (deal.stage) {
        queryClient.invalidateQueries({ queryKey: [`/api/deals/stage/${deal.stage}`] });
      }

      if (deal.stageId) {
        queryClient.invalidateQueries({ queryKey: [`/api/deals/stageId/${deal.stageId}`] });
      }
    },
    onError: (error: Error) => {
      console.error('Error deleting deal:', error);
    },
  });

  const handleDelete = () => {
    deleteMutation.mutate(deal.id);
    setIsDeleteDialogOpen(false);
  };

  const handleEditDeal = () => {
    setIsEditDealModalOpen(true);
  };

  const handleViewDetails = () => {
    setIsDealDetailsModalOpen(true);
  };

  const handleViewContact = () => {
    setIsContactDetailsModalOpen(true);
  };

  const handleContactClick = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    if (!contact?.id) return;

    // Redirect to inbox logic
    if (contact.identifierType) {
      localStorage.setItem('selectedContactId', contact.id.toString());
      localStorage.setItem('selectedChannelType', contact.identifierType);
      setLocation('/');
      toast({ title: "Redirecting...", description: `Opening chat with ${contact.name}` });
    } else {
      // Fallback if no identifier (e.g. manually created contact without channel)
      setIsContactDetailsModalOpen(true);
    }
  };

  const handleCardClick = () => {
    if (showSelectionMode && onSelect) {
      onSelect(deal, !isSelected);
    }
    // Removed default "View Details" on card click as per user request to avoid accidental modal opening.
    // Use the "View" button (eye icon) explicitly for details.
  };

  const priorityConfig = {
    low: {
      color: 'bg-blue-100 text-blue-700 border-blue-300',
      icon: ArrowDown,
      label: 'Baja'
    },
    medium: {
      color: 'bg-yellow-100 text-yellow-700 border-yellow-300',
      icon: ArrowRight,
      label: 'Media'
    },
    high: {
      color: 'bg-red-100 text-red-700 border-red-300',
      icon: ArrowUp,
      label: 'Alta'
    },
  };

  const priority = priorityConfig[deal.priority as keyof typeof priorityConfig] || priorityConfig.medium;
  const PriorityIcon = priority.icon;

  const getDueDateStatus = () => {
    if (!deal.dueDate) return null;
    const now = new Date();
    const dueDate = new Date(deal.dueDate);
    const diffTime = dueDate.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays < 0) {
      return { status: 'overdue', color: 'text-red-600 bg-red-50 border-red-200', label: 'Vencida' };
    } else if (diffDays <= 3) {
      return { status: 'soon', color: 'text-orange-600 bg-orange-50 border-orange-200', label: 'Próxima' };
    } else if (diffDays <= 7) {
      return { status: 'upcoming', color: 'text-blue-600 bg-blue-50 border-blue-200', label: 'Esta semana' };
    }
    return { status: 'normal', color: 'text-gray-600 bg-gray-50 border-gray-200', label: 'Programada' };
  };

  const dueDateStatus = getDueDateStatus();

  return (
    <div
      className={`bg-card border rounded-lg shadow-sm hover:shadow-md transition-all duration-200 cursor-grab group relative hover:border-blue-300 mb-3 flex flex-col ${isSelected ? 'ring-2 ring-blue-500 border-blue-500' : ''}`}
      onClick={handleCardClick}
    >
      {/* Selection Checkbox */}
      {showSelectionMode && (
        <div className="absolute top-2 left-2 z-20">
          <Checkbox
            checked={isSelected}
            onCheckedChange={(checked) => onSelect?.(deal, !!checked)}
            onClick={(e) => e.stopPropagation()}
            className="bg-white border-2 border-gray-300 shadow-sm"
          />
        </div>
      )}

      {/* Quick Actions Overlay */}
      <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center gap-1 z-30">
        {/* Actions kept same but maybe reduced for cleaner UI */}
        <Button variant="secondary" size="icon" className="h-7 w-7 bg-white/90 hover:bg-white border shadow-sm" onClick={(e) => { e.stopPropagation(); handleEditDeal(); }}><i className="ri-edit-line text-xs" /></Button>
        <Button variant="secondary" size="icon" className="h-7 w-7 bg-white/90 hover:bg-white border shadow-sm" onClick={(e) => { e.stopPropagation(); handleViewDetails(); }}><i className="ri-eye-line text-xs" /></Button>
        <DropdownMenu>
          <DropdownMenuTrigger asChild><Button variant="secondary" size="icon" className="h-7 w-7 bg-white/90 hover:bg-white border shadow-sm" onClick={(e) => e.stopPropagation()}><MoreHorizontal className="h-3.5 w-3.5" /></Button></DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={handleViewContact}>View Contact</DropdownMenuItem>
            <DropdownMenuItem onClick={(e) => handleContactClick(e)}>Message Contact</DropdownMenuItem>
            <DropdownMenuItem onClick={() => setIsDeleteDialogOpen(true)} className="text-destructive">Delete Deal</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* NEW HEADER: Contact & Priority */}
      <div className="p-3 pb-2 flex justify-between items-start gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <div onClick={handleContactClick} className="cursor-pointer">
            <ContactAvatar contact={contact || { name: 'Unknown' }} size="sm" className="h-8 w-8" />
          </div>
          <div className="flex flex-col min-w-0">
            <div className="flex items-center gap-1.5 group/name">
              <span
                className="font-semibold text-sm text-gray-900 truncate hover:text-blue-600 cursor-pointer"
                onClick={handleContactClick}
              >
                <HighlightedText text={contact?.name || 'Unknown Contact'} searchTerm={searchTerm} />
              </span>
              <div
                onClick={handleContactClick}
                className="cursor-pointer p-0.5 rounded-full hover:bg-green-50 transition-colors"
                title="Open Chat"
              >
                <MessageCircle className="h-3.5 w-3.5 text-green-600" />
              </div>
            </div>
            {/* Identifier Icon if available in future, or small label */}
          </div>
        </div>
        <div className="flex items-center gap-1 shrink-0">
          {assignedUser && (
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger>
                  <div className="w-6 h-6 rounded-full bg-gray-100 flex items-center justify-center text-[10px] border border-white ring-1 ring-gray-200 font-bold text-gray-600">
                    {(assignedUser.fullName || assignedUser.username).charAt(0).toUpperCase()}
                  </div>
                </TooltipTrigger>
                <TooltipContent>{assignedUser.fullName}</TooltipContent>
              </Tooltip>
            </TooltipProvider>
          )}

          {/* Priority Badge */}
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger asChild>
                <div className={`p-1 rounded-md border ${priority.color}`}>
                  <PriorityIcon className="h-3 w-3" />
                </div>
              </TooltipTrigger>
              <TooltipContent><p>{priority.label}</p></TooltipContent>
            </Tooltip>
          </TooltipProvider>
        </div>
      </div>

      {/* BODY: Deal Title (Interest) & Description */}
      <div className="px-3 pb-2 -mt-1">
        {deal.title && (
          <div className="text-sm font-medium text-gray-700 leading-tight mb-1 flex items-center gap-1">
            <span className="truncate block w-full"><HighlightedText text={deal.title} searchTerm={searchTerm} /></span>
          </div>
        )}

        {/* Linked Properties Names */}
        {linkedProperties && linkedProperties.length > 0 && (
          <div className="text-xs text-blue-600 mb-1.5 flex flex-col gap-0.5">
            {linkedProperties.slice(0, 3).map((prop: any) => (
              <div key={prop.id} className="flex items-center gap-1 truncate hover:underline cursor-pointer">
                <Home className="h-3 w-3 shrink-0 opacity-70" />
                <span className="truncate max-w-full">{prop.title || prop.name}</span>
              </div>
            ))}
            {linkedProperties.length > 3 && (
              <span className="text-[10px] pl-4 text-gray-500">+ {linkedProperties.length - 3} más</span>
            )}
          </div>
        )}

        {deal.value && (
          <div className="text-sm font-semibold text-green-700/90 mb-1">
            ${new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(deal.value)}
          </div>
        )}
      </div>

      {/* FOOTER: Meta info & Properties */}
      <div className="mt-auto px-3 py-2 border-t border-gray-100 bg-gray-50/50 flex items-center justify-between gap-2 text-xs">
        <div className="flex items-center gap-2">
          {/* Due Date */}
          {deal.dueDate && (
            <div className={`flex items-center gap-1 ${dueDateStatus?.color} px-1.5 py-0.5 rounded border whitespace-nowrap`}>
              <Calendar className="h-3 w-3" />
              <span>{new Date(deal.dueDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
            </div>
          )}

          {/* PROPERTY COUNT BADGE */}
          {deal.propertyCount && deal.propertyCount > 0 ? (
            <div className="flex items-center gap-1 bg-indigo-50 text-indigo-700 border border-indigo-200 px-1.5 py-0.5 rounded">
              <Home className="h-3 w-3" />
              <span className="font-medium">{deal.propertyCount}</span>
            </div>
          ) : null}
        </div>

        {/* Tags moved to footer - Limited to 2 and using ... for overflow */}
        {deal.tags && deal.tags.length > 0 && (
          <div className="flex flex-nowrap items-center gap-1 mr-auto overflow-hidden">
            {deal.tags.slice(0, 2).map((tag, index) => (
              <div key={index} className="shrink-0">
                <ColoredTag name={tag} color={(tagColorsMap.get(tag) as string | null) || undefined} size="sm" />
              </div>
            ))}
            {deal.tags.length > 2 && (
              <Badge variant="outline" className="text-[10px] px-1 h-5 flex items-center bg-gray-100 text-gray-500 shrink-0">
                ...
              </Badge>
            )}
          </div>
        )}

        <div className="flex items-center gap-2 text-gray-500 shrink-0">
          {commentCount > 0 && <span className="flex items-center gap-0.5"><MessageSquare className="h-3 w-3" />{commentCount}</span>}
          {checklistProgress.total > 0 && (
            <span className={`flex items-center gap-0.5 ${checklistProgress.completed === checklistProgress.total ? 'text-green-600' : ''}`}>
              <CheckCircle2 className="h-3 w-3" /> {checklistProgress.completed}/{checklistProgress.total}
            </span>
          )}
        </div>
      </div>

      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the deal "{deal.title}" from your pipeline. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <EditDealModal
        deal={deal}
        isOpen={isEditDealModalOpen}
        onClose={() => setIsEditDealModalOpen(false)}
        pipelineId={pipelineId}
      />

      <DealDetailsModal
        deal={deal}
        isOpen={isDealDetailsModalOpen}
        onClose={() => setIsDealDetailsModalOpen(false)}
      />

      <ContactDetailsModal
        contactId={deal.contactId}
        isOpen={isContactDetailsModalOpen}
        onClose={() => setIsContactDetailsModalOpen(false)}
      />
    </div>
  );
}