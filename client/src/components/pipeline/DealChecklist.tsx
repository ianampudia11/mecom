import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';
import { Progress } from '@/components/ui/progress';
import {
    CheckSquare,
    Plus,
    Trash2,
    GripVertical,
    Edit2,
    X
} from 'lucide-react';
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

interface ChecklistItem {
    id: number;
    checklistId: number;
    text: string;
    isCompleted: boolean;
    orderNum: number;
    completedAt: string | null;
    completedBy: number | null;
    createdAt: string;
    updatedAt: string;
}

interface Checklist {
    id: number;
    dealId: number;
    title: string;
    orderNum: number;
    items: ChecklistItem[];
    createdAt: string;
    updatedAt: string;
}

interface DealChecklistProps {
    dealId: number;
}

export default function DealChecklist({ dealId }: DealChecklistProps) {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [newChecklistTitle, setNewChecklistTitle] = useState('');
    const [newItemTexts, setNewItemTexts] = useState<{ [key: number]: string }>({});
    const [editingItem, setEditingItem] = useState<number | null>(null);
    const [editingText, setEditingText] = useState('');
    const [checklistToDelete, setChecklistToDelete] = useState<number | null>(null);

    // Fetch checklists
    const { data: checklists = [], isLoading } = useQuery<Checklist[]>({
        queryKey: [`/api/deals/${dealId}/checklists`],
        queryFn: async () => {
            const res = await apiRequest('GET', `/api/deals/${dealId}/checklists`);
            if (!res.ok) throw new Error('Failed to fetch checklists');
            return res.json();
        },
    });

    // Create checklist mutation
    const createChecklistMutation = useMutation({
        mutationFn: async (title: string) => {
            const res = await apiRequest('POST', `/api/deals/${dealId}/checklists`, { title });
            if (!res.ok) throw new Error('Failed to create checklist');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/checklists`] });
            setNewChecklistTitle('');
            toast({
                title: 'Checklist creado',
                description: 'El checklist ha sido creado exitosamente.',
            });
        },
        onError: () => {
            toast({
                title: 'Error',
                description: 'No se pudo crear el checklist.',
                variant: 'destructive',
            });
        },
    });

    // Delete checklist mutation
    const deleteChecklistMutation = useMutation({
        mutationFn: async (checklistId: number) => {
            const res = await apiRequest('DELETE', `/api/checklists/${checklistId}`);
            if (!res.ok) throw new Error('Failed to delete checklist');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/checklists`] });
            setChecklistToDelete(null);
            toast({
                title: 'Checklist eliminado',
                description: 'El checklist ha sido eliminado exitosamente.',
            });
        },
    });

    // Create item mutation
    const createItemMutation = useMutation({
        mutationFn: async ({ checklistId, text }: { checklistId: number; text: string }) => {
            const res = await apiRequest('POST', `/api/checklists/${checklistId}/items`, { text });
            if (!res.ok) throw new Error('Failed to create item');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/checklists`] });
            setNewItemTexts({});
        },
    });

    // Toggle item mutation
    const toggleItemMutation = useMutation({
        mutationFn: async ({ itemId, isCompleted }: { itemId: number; isCompleted: boolean }) => {
            const res = await apiRequest('PUT', `/api/checklist-items/${itemId}`, { isCompleted });
            if (!res.ok) throw new Error('Failed to toggle item');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/checklists`] });
        },
    });

    // Update item text mutation
    const updateItemMutation = useMutation({
        mutationFn: async ({ itemId, text }: { itemId: number; text: string }) => {
            const res = await apiRequest('PUT', `/api/checklist-items/${itemId}`, { text });
            if (!res.ok) throw new Error('Failed to update item');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/checklists`] });
            setEditingItem(null);
            setEditingText('');
        },
    });

    // Delete item mutation
    const deleteItemMutation = useMutation({
        mutationFn: async (itemId: number) => {
            const res = await apiRequest('DELETE', `/api/checklist-items/${itemId}`);
            if (!res.ok) throw new Error('Failed to delete item');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/checklists`] });
        },
    });

    const handleCreateChecklist = () => {
        if (!newChecklistTitle.trim()) return;
        createChecklistMutation.mutate(newChecklistTitle);
    };

    const handleAddItem = (checklistId: number) => {
        const text = newItemTexts[checklistId];
        if (!text?.trim()) return;
        createItemMutation.mutate({ checklistId, text });
    };

    const handleToggleItem = (itemId: number, isCompleted: boolean) => {
        toggleItemMutation.mutate({ itemId, isCompleted: !isCompleted });
    };

    const handleStartEdit = (item: ChecklistItem) => {
        setEditingItem(item.id);
        setEditingText(item.text);
    };

    const handleSaveEdit = (itemId: number) => {
        if (!editingText.trim()) return;
        updateItemMutation.mutate({ itemId, text: editingText });
    };

    const handleCancelEdit = () => {
        setEditingItem(null);
        setEditingText('');
    };

    const getProgress = (items: ChecklistItem[]) => {
        if (!items || items.length === 0) return 0;
        const completed = items.filter(item => item.isCompleted).length;
        return Math.round((completed / items.length) * 100);
    };

    if (isLoading) {
        return <div className="text-sm text-gray-500">Cargando checklists...</div>;
    }

    return (
        <div className="space-y-4">
            {/* Existing Checklists */}
            {checklists.map((checklist) => {
                const progress = getProgress(checklist.items || []);
                const completed = checklist.items?.filter(item => item.isCompleted).length || 0;
                const total = checklist.items?.length || 0;

                return (
                    <div key={checklist.id} className="border rounded-lg p-4 space-y-3">
                        {/* Checklist Header */}
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <CheckSquare className="h-5 w-5 text-gray-600" />
                                <h4 className="font-medium text-gray-900">{checklist.title}</h4>
                                <span className="text-sm text-gray-500">
                                    {completed}/{total}
                                </span>
                            </div>
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => setChecklistToDelete(checklist.id)}
                                className="text-red-600 hover:text-red-700 hover:bg-red-50"
                            >
                                <Trash2 className="h-4 w-4" />
                            </Button>
                        </div>

                        {/* Progress Bar */}
                        {total > 0 && (
                            <Progress value={progress} className="h-2" />
                        )}

                        {/* Checklist Items */}
                        <div className="space-y-2">
                            {checklist.items?.map((item) => (
                                <div
                                    key={item.id}
                                    className="flex items-start gap-2 group hover:bg-gray-50 p-2 rounded-md transition-colors"
                                >
                                    <Checkbox
                                        checked={item.isCompleted}
                                        onCheckedChange={() => handleToggleItem(item.id, item.isCompleted)}
                                        className="mt-0.5"
                                    />

                                    {editingItem === item.id ? (
                                        <div className="flex-1 flex items-center gap-2">
                                            <Input
                                                value={editingText}
                                                onChange={(e) => setEditingText(e.target.value)}
                                                onKeyDown={(e) => {
                                                    if (e.key === 'Enter') handleSaveEdit(item.id);
                                                    if (e.key === 'Escape') handleCancelEdit();
                                                }}
                                                className="text-sm"
                                                autoFocus
                                            />
                                            <Button
                                                size="sm"
                                                variant="ghost"
                                                onClick={() => handleSaveEdit(item.id)}
                                            >
                                                ✓
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="ghost"
                                                onClick={handleCancelEdit}
                                            >
                                                <X className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    ) : (
                                        <>
                                            <span
                                                className={`flex-1 text-sm ${item.isCompleted ? 'line-through text-gray-500' : 'text-gray-900'
                                                    }`}
                                            >
                                                {item.text}
                                            </span>
                                            <div className="opacity-0 group-hover:opacity-100 flex items-center gap-1 transition-opacity">
                                                <Button
                                                    size="sm"
                                                    variant="ghost"
                                                    onClick={() => handleStartEdit(item)}
                                                    className="h-7 w-7 p-0"
                                                >
                                                    <Edit2 className="h-3 w-3" />
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="ghost"
                                                    onClick={() => deleteItemMutation.mutate(item.id)}
                                                    className="h-7 w-7 p-0 text-red-600 hover:text-red-700"
                                                >
                                                    <Trash2 className="h-3 w-3" />
                                                </Button>
                                            </div>
                                        </>
                                    )}
                                </div>
                            ))}
                        </div>

                        {/* Add New Item */}
                        <div className="flex items-center gap-2 pt-2">
                            <Input
                                placeholder="Agregar item..."
                                value={newItemTexts[checklist.id] || ''}
                                onChange={(e) =>
                                    setNewItemTexts({ ...newItemTexts, [checklist.id]: e.target.value })
                                }
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter') handleAddItem(checklist.id);
                                }}
                                className="text-sm"
                            />
                            <Button
                                size="sm"
                                onClick={() => handleAddItem(checklist.id)}
                                disabled={!newItemTexts[checklist.id]?.trim()}
                            >
                                <Plus className="h-4 w-4" />
                            </Button>
                        </div>
                    </div>
                );
            })}

            {/* Create New Checklist */}
            <div className="border-2 border-dashed rounded-lg p-4">
                <div className="flex items-center gap-2">
                    <Input
                        placeholder="Nuevo checklist..."
                        value={newChecklistTitle}
                        onChange={(e) => setNewChecklistTitle(e.target.value)}
                        onKeyDown={(e) => {
                            if (e.key === 'Enter') handleCreateChecklist();
                        }}
                    />
                    <Button
                        onClick={handleCreateChecklist}
                        disabled={!newChecklistTitle.trim() || createChecklistMutation.isPending}
                    >
                        <Plus className="h-4 w-4 mr-2" />
                        Crear
                    </Button>
                </div>
            </div>

            {/* Delete Confirmation Dialog */}
            <AlertDialog
                open={checklistToDelete !== null}
                onOpenChange={() => setChecklistToDelete(null)}
            >
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>¿Eliminar checklist?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Esta acción eliminará el checklist y todos sus items. No se puede deshacer.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={() => checklistToDelete && deleteChecklistMutation.mutate(checklistToDelete)}
                            className="bg-red-600 hover:bg-red-700"
                        >
                            Eliminar
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}
