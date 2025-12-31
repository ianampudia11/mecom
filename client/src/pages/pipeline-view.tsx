import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/use-auth';
import useSocket from '@/hooks/useSocket';
import { Redirect } from 'wouter';
import { useQuery } from '@tanstack/react-query';
import Header from '@/components/layout/Header';
import Sidebar from '@/components/layout/Sidebar';
import KanbanBoard from '@/components/pipeline/KanbanBoard';
import PipelineList from '@/components/pipeline/PipelineList';
import EditDealModal from '@/components/pipeline/EditDealModal';
import AddDealModal from '@/components/pipeline/AddDealModal';
import ImportExportModal from '@/components/pipeline/ImportExportModal';
import BulkOperationsBar from '@/components/pipeline/BulkOperationsBar';
import PipelineSearchBar from '@/components/pipeline/PipelineSearchBar';
import QuickChatModal from "@/components/conversations/QuickChatModal";
import { AppointmentDialog } from "@/components/calendar/AppointmentDialog";
import { AppointmentHistoryDialog } from "@/components/calendar/AppointmentHistoryDialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  SelectSeparator,
} from "@/components/ui/select";
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Plus, Settings, Layout, List, Kanban, CheckSquare, Download } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { apiRequest } from '@/lib/queryClient';
import { Deal, PipelineStage } from '@shared/schema';

interface Pipeline {
  id: number;
  name: string;
}

export default function PipelineView() {
  const { user, isLoading } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [isAddDealModalOpen, setIsAddDealModalOpen] = useState(false);
  const [isEditDealModalOpen, setIsEditDealModalOpen] = useState(false);
  const [editingDeal, setEditingDeal] = useState<Deal | null>(null);
  // Quick Chat State
  const [quickChatDeal, setQuickChatDeal] = useState<Deal | null>(null);
  const [isQuickChatOpen, setIsQuickChatOpen] = useState(false);
  const [isCreatePipelineOpen, setIsCreatePipelineOpen] = useState(false);
  const [newPipelineName, setNewPipelineName] = useState('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedPipelineId, setSelectedPipelineId] = useState<number | null>(null);
  const [viewMode, setViewMode] = useState<'board' | 'list'>('list');

  // New State for Actions
  const [showSelectionMode, setShowSelectionMode] = useState(false);
  const [selectedDeals, setSelectedDeals] = useState<Deal[]>([]);
  const [showImportExportModal, setShowImportExportModal] = useState(false);
  const [isAddingStage, setIsAddingStage] = useState(false);
  const [newStageName, setNewStageName] = useState('');

  // Appointment Dialog State
  const [isAppointmentDialogOpen, setIsAppointmentDialogOpen] = useState(false);
  const [appointmentDeal, setAppointmentDeal] = useState<any | null>(null);

  // History Dialog State
  const [isHistoryDialogOpen, setIsHistoryDialogOpen] = useState(false);
  const [historyDeal, setHistoryDeal] = useState<any | null>(null);



  const { onMessage } = useSocket('/ws');

  useEffect(() => {
    const handleUpdate = () => {
      queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
    };

    const unsubNewMsg = onMessage('newMessage', handleUpdate);
    const unsubUpdate = onMessage('conversationUpdated', handleUpdate);
    const unsubUnread = onMessage('unreadCountUpdated', handleUpdate);

    return () => {
      unsubNewMsg();
      unsubUpdate();
      unsubUnread();
    };
  }, [onMessage, queryClient]);

  const createPipelineMutation = useMutation({
    mutationFn: async (name: string) => {
      const res = await fetch('/api/pipelines', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, description: 'Nueva Ruta de Lead' }),
      });
      if (!res.ok) throw new Error('Failed to create pipeline');
      return res.json();
    },
    onSuccess: (newItem: any) => {
      toast({ title: 'Ruta de Lead creada exitosamente' });
      setIsCreatePipelineOpen(false);
      setNewPipelineName('');
      queryClient.invalidateQueries({ queryKey: ['pipelines'] });
      // Select the new pipeline
      if (newItem?.id) {
        setSelectedPipelineId(newItem.id);
      }
    },
  });

  const handleCreatePipeline = () => {
    if (newPipelineName.trim()) {
      createPipelineMutation.mutate(newPipelineName);
    }
  };

  const createStageMutation = useMutation({
    mutationFn: async (data: { name: string, pipelineId: number }) => {
      const res = await apiRequest('POST', `/api/pipelines/${data.pipelineId}/stages`, {
        name: data.name,
        order: pipelineStages.length,
        color: '#E2E8F0'
      });
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pipeline-stages'] });
      setIsAddingStage(false);
      setNewStageName('');
      toast({ title: 'Etapa creada exitosamente' });
    }
  });

  const { data: pipelines = [] } = useQuery<Pipeline[]>({
    queryKey: ['pipelines'],
    queryFn: async () => {
      const res = await fetch('/api/pipelines');
      if (!res.ok) throw new Error('Failed to fetch pipelines');
      return res.json();
    },
  });

  // Fetch Stages
  const { data: pipelineStages = [], isLoading: isLoadingStages } = useQuery<PipelineStage[]>({
    queryKey: ['pipeline-stages', selectedPipelineId],
    queryFn: async () => {
      const url = selectedPipelineId
        ? `/api/pipelines/${selectedPipelineId}/stages`
        : '/api/pipeline/stages';
      const res = await apiRequest('GET', url);
      return res.json();
    },
    enabled: !!selectedPipelineId
  });

  // Fetch Deals
  const { data: deals = [], isLoading: isLoadingDeals } = useQuery<Deal[]>({
    queryKey: ['/api/deals', searchTerm, selectedPipelineId],
    queryFn: async () => {
      const queryParams = new URLSearchParams();
      if (searchTerm) {
        queryParams.append('generalSearch', searchTerm);
      }
      // Note: Backend doesn't strictly filter by pipelineId on /api/deals yet, 
      // but client-side filtering logic depends on stageId mapping.
      const url = `/api/deals${queryParams.toString() ? `?${queryParams.toString()}` : ''}`;
      const res = await apiRequest('GET', url);
      return res.json();
    },
  });

  // Set default pipeline
  useEffect(() => {
    if (pipelines.length > 0 && !selectedPipelineId) {
      setSelectedPipelineId(pipelines[0].id);
    }
  }, [pipelines, selectedPipelineId]);

  // Fetch Team Members
  const { data: teamMembers = [] } = useQuery({
    queryKey: ['teamMembers'],
    queryFn: async () => {
      const res = await apiRequest('GET', '/api/team-members');
      const data = await res.json();
      return data;
    }
  });

  const [stageFilter, setStageFilter] = useState<string>('all');
  const [assigneeFilter, setAssigneeFilter] = useState<string>('all');
  const [tagFilter, setTagFilter] = useState<string>('all');
  const [propertyFilter, setPropertyFilter] = useState<string>('all');

  // Fetch Tags and Properties (reusing what we saw in AddDealModal)
  const { data: availableTags = [] } = useQuery({
    queryKey: ['/api/contacts/tags'],
    queryFn: async () => {
      const res = await fetch('/api/contacts/tags');
      if (!res.ok) return [];
      const data = await res.json();
      return Array.isArray(data) ? data : [];
    }
  });

  const { data: properties = [] } = useQuery({
    queryKey: ['/api/properties'],
    queryFn: () => apiRequest('GET', '/api/properties').then(res => res.json())
  });

  // Filter Deals Logic
  const filteredDeals = deals.filter((deal: Deal) => {
    const matchesStage = stageFilter === 'all' || deal.stageId === parseInt(stageFilter);
    // Note: deal.assignedTo might be string email or ID depending on schema, assume email or check schema. 
    // In tasks.tsx it was string. In pipeline, let's check schema/previous `AddDealModal`.
    // AddDealModal used `teamMembers` and `deal.assignedTo`.
    // Let's assume deal.assignedTo is strictly comparable to filter or check if filter 'all'.
    // If deal.assignedTo matches assigneeFilter (which comes from team member email or id).
    // Let's verify schema or usage. AddDealModal uses member.id.
    const matchesAssignee = assigneeFilter === 'all' || (deal as any).assignedTo === assigneeFilter || (deal as any).userId === parseInt(assigneeFilter);
    const matchesTag = tagFilter === 'all' || ((deal as any).tags && (deal as any).tags.includes(tagFilter));

    // Property matching: deal.properties is array of {id, title}. We check if any property matches the ID.
    const matchesProperty = propertyFilter === 'all' || ((deal as any).properties && (deal as any).properties.some((p: any) => p.id === parseInt(propertyFilter)));

    // Verify deal belongs to current pipeline (backend returns all deals)
    const matchesPipeline = pipelineStages.some(stage => stage.id === deal.stageId);

    return matchesStage && matchesAssignee && matchesTag && matchesProperty && matchesPipeline;
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!user) {
    return <Redirect to="/auth" />;
  }

  return (
    <div className="h-screen flex flex-col overflow-hidden font-sans text-gray-800">
      <Header />
      <div className="flex flex-1 overflow-hidden">
        <Sidebar />
        <main className="flex-1 overflow-y-auto">
          <div className="container mx-auto px-4 py-6">

            {/* Header & Controls */}
            <div className="mb-6 space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-bold text-gray-900">Ruta de Lead</h1>
                  <p className="mt-1 text-sm text-gray-500">Gestiona tus oportunidades comerciales</p>
                </div>
                <div className="flex items-center gap-3">
                  {/* View Toggle */}
                  <div className="hidden md:flex items-center border border-gray-200 rounded-lg p-1 bg-white">
                    <Button
                      variant={viewMode === 'board' ? 'default' : 'ghost'}
                      size="sm"
                      onClick={() => setViewMode('board')}
                    >
                      <Kanban className="h-4 w-4" />
                      Tablero
                    </Button>
                    <Button
                      variant={viewMode === 'list' ? 'default' : 'ghost'}
                      size="sm"
                      onClick={() => setViewMode('list')}
                      className="flex items-center gap-2 h-8 px-3"
                    >
                      <List className="h-4 w-4" />
                      Lista
                    </Button>
                  </div>

                  <PipelineSearchBar
                    onSearchChange={setSearchTerm}
                    initialValue={searchTerm}
                    className="w-[300px]"
                  />

                  <Select
                    value={selectedPipelineId?.toString()}
                    onValueChange={(val) => {
                      if (val === 'create_new') {
                        setIsCreatePipelineOpen(true);
                      } else {
                        setSelectedPipelineId(parseInt(val));
                      }
                    }}
                  >
                    <SelectTrigger className="w-[200px] h-9">
                      <SelectValue placeholder="Ruta Principal" />
                    </SelectTrigger>
                    <SelectContent>
                      {pipelines.length === 0 ? (
                        <SelectItem value="none" disabled>No pipelines found</SelectItem>
                      ) : (
                        pipelines.map((p) => (
                          <SelectItem key={p.id} value={p.id.toString()}>
                            {p.name}
                          </SelectItem>
                        ))
                      )}
                      <SelectSeparator />
                      <SelectItem value="create_new" className="text-primary font-medium focus:text-primary focus:bg-primary/10 cursor-pointer">
                        <div className="flex items-center gap-2">
                          <Plus className="h-4 w-4" />
                          Crear Nueva Ruta
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>

                  <Button
                    onClick={() => setIsAddDealModalOpen(true)}
                    className="flex items-center gap-2 h-9"
                  >
                    <Plus className="h-4 w-4" />
                    Agregar oportunidad
                  </Button>

                  <Button variant="ghost" size="icon" asChild title="Configurar Rutas Lead">
                    <a href="/settings/pipelines">
                      <Settings className="h-5 w-5 text-gray-500" />
                    </a>
                  </Button>
                </div>
              </div>



              {/* Filters Row - Styled like Tasks */}
              <div className="flex flex-wrap gap-4 items-center bg-white p-3 rounded-lg border shadow-sm">
                {/* Stage Filter */}
                <div className="w-[200px]">
                  <Select value={stageFilter} onValueChange={setStageFilter}>
                    <SelectTrigger className="h-9">
                      <SelectValue placeholder="Todos los estados" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Todos los estados</SelectItem>
                      {pipelineStages.map((stage) => (
                        <SelectItem key={stage.id} value={stage.id.toString()}>
                          <div className="flex items-center gap-2">
                            <div className="h-2 w-2 rounded-full" style={{ backgroundColor: stage.color }} />
                            {stage.name}
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Assignee Filter */}
                <div className="w-[200px]">
                  <Select value={assigneeFilter} onValueChange={setAssigneeFilter}>
                    <SelectTrigger className="h-9">
                      <SelectValue placeholder="Todos los asignados" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Todos los asignados</SelectItem>
                      {teamMembers.map((member: any) => (
                        // value should match deal.assignedTo type. Assuming ID for now or checking usage
                        <SelectItem key={member.id} value={member.id.toString()}>
                          {member.fullName || member.username}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Tag Filter */}
                <div className="w-[200px]">
                  <Select value={tagFilter} onValueChange={setTagFilter}>
                    <SelectTrigger className="h-9">
                      <SelectValue placeholder="Todas las etiquetas" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Todas las etiquetas</SelectItem>
                      {availableTags.map((tag: string) => (
                        <SelectItem key={tag} value={tag}>
                          {tag}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Property Filter */}
                <div className="w-[200px]">
                  <Select value={propertyFilter} onValueChange={setPropertyFilter}>
                    <SelectTrigger className="h-9">
                      <SelectValue placeholder="Todas las propiedades" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Todas las propiedades</SelectItem>
                      {properties.map((property: any) => (
                        <SelectItem key={property.id} value={property.id.toString()}>
                          {property.title || property.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>



                {/* Right Aligned Action Buttons */}
                <div className="ml-auto flex items-center gap-2">
                  <Button
                    variant={showSelectionMode ? "default" : "outline"}
                    size="sm"
                    onClick={() => {
                      setShowSelectionMode(!showSelectionMode);
                      if (showSelectionMode) setSelectedDeals([]);
                    }}
                    className="flex items-center gap-1 h-9"
                  >
                    <CheckSquare className="h-4 w-4" />
                    Select Deals
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setShowImportExportModal(true)}
                    className="flex items-center gap-1 h-9"
                  >
                    <Download className="h-4 w-4" />
                    Import/Export
                  </Button>
                </div>

              </div>
            </div>

            {/* List/Board View */}
            <div className="h-[calc(100vh-220px)] overflow-y-auto">
              {viewMode === 'board' ? (
                <KanbanBoard
                  deals={filteredDeals}
                  pipelineStages={pipelineStages}
                  pipelineId={selectedPipelineId || undefined}
                  searchTerm={searchTerm}
                  isLoading={isLoadingDeals || isLoadingStages}
                  onAddDeal={() => setIsAddDealModalOpen(true)}
                  showSelectionMode={showSelectionMode}
                  selectedDeals={selectedDeals}
                  onDealSelect={(deal, selected) => {
                    if (selected) {
                      setSelectedDeals(prev => [...prev, deal]);
                    } else {
                      setSelectedDeals(prev => prev.filter(d => d.id !== deal.id));
                    }
                  }}
                  onClearSelection={() => setSelectedDeals([])}
                  onUpdateDeals={() => {
                    queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
                  }}
                />
              ) : (
                <PipelineList
                  deals={filteredDeals}
                  pipelineStages={pipelineStages}
                  onDealClick={(deal) => {
                    setEditingDeal(deal);
                    setIsEditDealModalOpen(true);
                  }}
                  onMessageClick={(deal: any) => {
                    if (deal.contactId) {
                      setQuickChatDeal(deal);
                      setIsQuickChatOpen(true);
                    } else {
                      // If no contact, maybe just open edit modal or toast
                      setEditingDeal(deal);
                      setIsEditDealModalOpen(true);
                    }
                  }}
                  showSelectionMode={showSelectionMode}
                  selectedDeals={selectedDeals}
                  onDealSelect={(deal, selected) => {
                    if (selected) {
                      setSelectedDeals(prev => [...prev, deal]);
                    } else {
                      setSelectedDeals(prev => prev.filter(d => d.id !== deal.id));
                    }
                  }}
                  onScheduleAppointment={(deal) => {
                    setAppointmentDeal(deal);
                    setIsAppointmentDialogOpen(true);
                  }}
                  onViewHistory={(deal) => {
                    setHistoryDeal(deal);
                    setIsHistoryDialogOpen(true);
                  }}
                />
              )}
            </div>
          </div>
        </main>
      </div>

      <Dialog open={isCreatePipelineOpen} onOpenChange={setIsCreatePipelineOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Crear Nueva Ruta de Lead</DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <Input
              placeholder="Nombre de la ruta"
              value={newPipelineName}
              onChange={(e) => setNewPipelineName(e.target.value)}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsCreatePipelineOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleCreatePipeline}>Crear</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AddDealModal
        isOpen={isAddDealModalOpen}
        onClose={() => setIsAddDealModalOpen(false)}
        pipelineId={selectedPipelineId || undefined}
      />

      <EditDealModal
        isOpen={isEditDealModalOpen}
        onClose={() => setIsEditDealModalOpen(false)}
        deal={editingDeal}
        pipelineId={selectedPipelineId || undefined}
      />

      {quickChatDeal && (
        <QuickChatModal
          isOpen={isQuickChatOpen}
          onClose={() => {
            setIsQuickChatOpen(false);
            setQuickChatDeal(null);
          }}
          contactId={quickChatDeal.contactId}
          dealId={quickChatDeal.id}
        />
      )}

      {/* Appointment Dialog */}
      <AppointmentDialog
        open={isAppointmentDialogOpen}
        onOpenChange={setIsAppointmentDialogOpen}
        initialData={appointmentDeal ? {
          summary: `Cita con ${appointmentDeal.contact?.name || 'Cliente'}`,
          description: `Detalles del Trato: ${appointmentDeal.title}\nTeléfono: ${appointmentDeal.contact?.phone || 'N/A'}\nContacto: ${appointmentDeal.contact?.email || appointmentDeal.contact?.name || 'N/A'}`,
          attendees: appointmentDeal.contact?.email ? [appointmentDeal.contact.email] : []
        } : undefined}
      />

      <AppointmentHistoryDialog
        open={isHistoryDialogOpen}
        onOpenChange={setIsHistoryDialogOpen}
        deal={historyDeal}
      />

      {/* Import/Export Modal */}
      <ImportExportModal
        isOpen={showImportExportModal}
        onClose={() => setShowImportExportModal(false)}
      />

      {/* Add Stage Dialog */}
      <Dialog open={isAddingStage} onOpenChange={setIsAddingStage}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Agregar Nueva Etapa</DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <Input
              placeholder="Nombre de la etapa"
              value={newStageName}
              onChange={(e) => setNewStageName(e.target.value)}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddingStage(false)}>
              Cancelar
            </Button>
            <Button onClick={() => {
              if (newStageName.trim() && selectedPipelineId) {
                createStageMutation.mutate({
                  name: newStageName,
                  pipelineId: selectedPipelineId
                });
              }
            }}>
              Agregar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Bulk Operations Bar - Lifted from KanbanBoard */}
      <BulkOperationsBar
        selectedDeals={selectedDeals}
        stages={pipelineStages}
        users={teamMembers}
        onClearSelection={() => setSelectedDeals([])}
        onUpdateDeals={() => {
          queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
        }}
      />
    </div >
  );
}