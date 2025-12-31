import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useRoute } from 'wouter';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { ArrowLeft, GripVertical, Plus, Trash2, Save } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';
import 'tailwindcss/tailwind.css';

interface Stage {
    id?: number;
    name: string;
    color: string;
    order_index: number;
    tempId?: string; // For new stages not yet saved
}

const PRESET_COLORS = [
    '#3B82F6', '#EAB308', '#F97316', '#A855F7', '#EC4899', '#22C55E', '#EF4444', '#6366F1'
];

export default function PipelineEditor() {
    const [match, params] = useRoute('/settings/pipelines/:id');
    const pipelineId = params?.id ? parseInt(params.id) : null;

    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [stages, setStages] = useState<Stage[]>([]);
    const [hasChanges, setHasChanges] = useState(false);

    const { data: pipelineData } = useQuery({
        queryKey: ['pipelines'],
        queryFn: async () => {
            const res = await fetch('/api/pipelines');
            if (!res.ok) throw new Error('Failed to fetch pipelines');
            return res.json();
        },
        select: (data: any[]) => data.find((p) => p.id === pipelineId),
        enabled: !!pipelineId
    });

    const { data: serverStages, isLoading } = useQuery({
        queryKey: ['pipeline-stages', pipelineId],
        queryFn: async () => {
            const res = await fetch(`/api/pipelines/${pipelineId}/stages`);
            if (!res.ok) throw new Error('Failed to fetch stages');
            return res.json();
        },
        enabled: !!pipelineId
    });

    // Sync local state with server data
    useEffect(() => {
        if (serverStages) {
            setStages(serverStages);
        }
    }, [serverStages]);

    const saveMutation = useMutation({
        mutationFn: async (newStages: Stage[]) => {
            // Map to backend expected format (order_num instead of order_index)
            const stagesToSave = newStages.map(s => ({
                ...s,
                order_num: s.order_index
            }));

            const res = await fetch(`/api/pipelines/${pipelineId}/stages/reorder`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ stages: stagesToSave }),
            });
            if (!res.ok) throw new Error('Failed to save stages');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Cambios guardados correctamente' });
            setHasChanges(false);
            queryClient.invalidateQueries({ queryKey: ['pipeline-stages', pipelineId] });
        },
    });

    const deleteStageMutation = useMutation({
        mutationFn: async (stageId: number) => {
            const res = await fetch(`/api/pipeline-stages/${stageId}`, {
                method: 'DELETE',
            });
            if (!res.ok) {
                const error = await res.json();
                throw new Error(error.error || 'Failed to delete stage');
            }
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Etapa eliminada' });
            queryClient.invalidateQueries({ queryKey: ['pipeline-stages', pipelineId] });
        },
        onError: (err: Error) => {
            toast({
                title: 'Error al eliminar',
                description: err.message,
                variant: 'destructive'
            });
        }
    });

    const handleDragEnd = (result: any) => {
        if (!result.destination) return;

        const items = Array.from(stages);
        const [reorderedItem] = items.splice(result.source.index, 1);
        items.splice(result.destination.index, 0, reorderedItem);

        // Update order indexes locally
        const updatedStages = items.map((item, index) => ({
            ...item,
            order_index: index
        }));

        setStages(updatedStages);
        setHasChanges(true);
    };

    const handleStageChange = (index: number, field: keyof Stage, value: string) => {
        const newStages = [...stages];
        newStages[index] = { ...newStages[index], [field]: value };
        setStages(newStages);
        setHasChanges(true);
    };

    const addStage = () => {
        const newStage: Stage = {
            name: 'Nueva Etapa',
            color: PRESET_COLORS[stages.length % PRESET_COLORS.length],
            order_index: stages.length,
            tempId: `temp-${Date.now()}`
        };
        setStages([...stages, newStage]);
        setHasChanges(true);
    };

    const removeStage = (index: number) => {
        const stage = stages[index];

        // If it's an existing stage (has real ID), we need to delete it via API directly
        // or we can just remove from UI and let 'save' handle it? 
        // The previous implementation of reorder API doesn't handle deletions implicitly.
        // So better to delete explicitly if it has ID.

        if (stage.id) {
            if (confirm('¿Seguro que quieres eliminar esta etapa? Si tiene leads activos no se podrá eliminar.')) {
                deleteStageMutation.mutate(stage.id);
            }
        } else {
            // Just remove from local state
            const newStages = stages.filter((_, i) => i !== index);
            setStages(newStages);
            setHasChanges(true);
        }
    };

    if (!pipelineId) return <div>Falta ID de Ruta</div>;
    if (isLoading) return <div>Cargando etapas...</div>;

    return (
        <div className="max-w-4xl mx-auto py-8">
            <div className="flex items-center gap-4 mb-8">
                <Button variant="ghost" size="icon" asChild>
                    <a href="/settings/pipelines">
                        <ArrowLeft className="h-5 w-5" />
                    </a>
                </Button>
                <div>
                    <h2 className="text-2xl font-bold">{pipelineData?.name || 'Editar Ruta'}</h2>
                    <p className="text-muted-foreground">Arrastra para reordenar las etapas de venta</p>
                </div>
                <div className="ml-auto flex gap-2">
                    <Button onClick={addStage} variant="outline">
                        <Plus className="h-4 w-4 mr-2" />
                        Agregar Etapa
                    </Button>
                    <Button
                        onClick={() => saveMutation.mutate(stages)}
                        disabled={!hasChanges || saveMutation.isPending}
                    >
                        {saveMutation.isPending ? 'Guardando...' : 'Guardar Cambios'}
                        <Save className="h-4 w-4 ml-2" />
                    </Button>
                </div>
            </div>

            <div className="bg-card border rounded-lg p-6">
                <div className="grid grid-cols-12 gap-4 mb-4 text-sm font-medium text-muted-foreground px-2">
                    <div className="col-span-1">orden</div>
                    <div className="col-span-6">nombre de etapa</div>
                    <div className="col-span-4">color</div>
                    <div className="col-span-1"></div>
                </div>

                <DragDropContext onDragEnd={handleDragEnd}>
                    <Droppable droppableId="stages">
                        {(provided) => (
                            <div {...provided.droppableProps} ref={provided.innerRef} className="space-y-2">
                                {stages.map((stage, index) => (
                                    <Draggable
                                        key={stage.id?.toString() || stage.tempId || index.toString()}
                                        draggableId={stage.id?.toString() || stage.tempId || index.toString()}
                                        index={index}
                                    >
                                        {(provided) => (
                                            <div
                                                ref={provided.innerRef}
                                                {...provided.draggableProps}
                                                className="grid grid-cols-12 gap-4 items-center p-3 bg-white border rounded-md shadow-sm hover:shadow-md transition-shadow group"
                                            >
                                                <div className="col-span-1 flex justify-center">
                                                    <div {...provided.dragHandleProps} className="cursor-grab text-gray-400 hover:text-gray-600">
                                                        <GripVertical className="h-5 w-5" />
                                                    </div>
                                                </div>

                                                <div className="col-span-6">
                                                    <Input
                                                        value={stage.name}
                                                        onChange={(e) => handleStageChange(index, 'name', e.target.value)}
                                                        className="font-medium"
                                                    />
                                                </div>

                                                <div className="col-span-4 flex items-center gap-2">
                                                    <div
                                                        className="h-8 w-8 rounded-full cursor-pointer flex-shrink-0 border-2 border-transparent hover:scale-110 transition-transform"
                                                        style={{ backgroundColor: stage.color }}
                                                    />
                                                    <select
                                                        className="text-sm border rounded p-1 w-full text-muted-foreground"
                                                        value={stage.color}
                                                        onChange={(e) => handleStageChange(index, 'color', e.target.value)}
                                                    >
                                                        {PRESET_COLORS.map(c => (
                                                            <option key={c} value={c}>
                                                                {c}
                                                            </option>
                                                        ))}
                                                    </select>
                                                </div>

                                                <div className="col-span-1 flex justify-end">
                                                    <Button
                                                        variant="ghost"
                                                        size="icon"
                                                        className="text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
                                                        onClick={() => removeStage(index)}
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                </div>
                                            </div>
                                        )}
                                    </Draggable>
                                ))}
                                {provided.placeholder}
                            </div>
                        )}
                    </Droppable>
                </DragDropContext>
            </div>
        </div>
    );
}
