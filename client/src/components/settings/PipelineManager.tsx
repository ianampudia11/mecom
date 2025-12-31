import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Settings2, Pencil, Trash2, Check, X, Layout } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
    DialogFooter,
} from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { ArrowLeft } from 'lucide-react';

interface Pipeline {
    id: number;
    name: string;
    description: string;
    is_default: boolean;
}

export default function PipelineManager() {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [isCreateOpen, setIsCreateOpen] = useState(false);
    const [newPipelineName, setNewPipelineName] = useState('');
    const [editingId, setEditingId] = useState<number | null>(null);
    const [editName, setEditName] = useState('');
    const [deleteId, setDeleteId] = useState<number | null>(null);

    const { data: pipelines = [], isLoading } = useQuery<Pipeline[]>({
        queryKey: ['pipelines'],
        queryFn: async () => {
            const res = await fetch('/api/pipelines');
            if (!res.ok) throw new Error('Failed to fetch pipelines');
            return res.json();
        },
    });

    const createMutation = useMutation({
        mutationFn: async (name: string) => {
            const res = await fetch('/api/pipelines', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, description: 'Ruta de lead personalizada' }),
            });
            if (!res.ok) throw new Error('Failed to create pipeline');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Ruta de Lead creada exitosamente' });
            setIsCreateOpen(false);
            setNewPipelineName('');
            queryClient.invalidateQueries({ queryKey: ['pipelines'] });
        },
    });

    const updateMutation = useMutation({
        mutationFn: async ({ id, name }: { id: number; name: string }) => {
            const res = await fetch(`/api/pipelines/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name }),
            });
            if (!res.ok) throw new Error('Failed to update pipeline');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Ruta de Lead actualizada' });
            setEditingId(null);
            queryClient.invalidateQueries({ queryKey: ['pipelines'] });
        },
        onError: (error: Error) => {
            toast({
                title: 'Error al actualizar',
                description: error.message,
                variant: 'destructive',
            });
        },
    });

    const deleteMutation = useMutation({
        mutationFn: async (id: number) => {
            const res = await fetch(`/api/pipelines/${id}`, {
                method: 'DELETE',
            });
            if (!res.ok) {
                const data = await res.json();
                throw new Error(data.error || 'Failed to delete pipeline');
            }
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Ruta de Lead eliminada' });
            setDeleteId(null);
            queryClient.invalidateQueries({ queryKey: ['pipelines'] });
        },
        onError: (error: Error) => {
            toast({
                title: 'Error al eliminar',
                description: error.message,
                variant: 'destructive'
            });
        }
    });

    const handleCreate = () => {
        if (newPipelineName.trim()) {
            createMutation.mutate(newPipelineName);
        }
    };

    const startEdit = (pipeline: Pipeline) => {
        setEditingId(pipeline.id);
        setEditName(pipeline.name);
    };

    const saveEdit = () => {
        if (editingId && editName.trim()) {
            updateMutation.mutate({ id: editingId, name: editName });
        }
    };

    if (isLoading) {
        return <div className="space-y-4">
            <Skeleton className="h-12 w-full" />
            <Skeleton className="h-12 w-full" />
            <Skeleton className="h-12 w-full" />
        </div>;
    }

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">

                <div>
                    <Button variant="ghost" className="mb-2 pl-0 hover:pl-2 transition-all" asChild>
                        <a href="/pipeline">
                            <ArrowLeft className="mr-2 h-4 w-4" />
                            Volver al Tablero
                        </a>
                    </Button>
                    <h2 className="text-2xl font-bold tracking-tight">Rutas de Lead</h2>
                    <p className="text-muted-foreground">Configura los diferentes flujos de venta para tu inmobiliaria.</p>
                </div>
                <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
                    <DialogTrigger asChild>
                        <Button>
                            <Plus className="mr-2 h-4 w-4" />
                            Nueva Ruta
                        </Button>
                    </DialogTrigger>
                    <DialogContent>
                        <DialogHeader>
                            <DialogTitle>Crear Nueva Ruta de Lead</DialogTitle>
                        </DialogHeader>
                        <div className="py-4">
                            <Input
                                placeholder="Ej. Renta, Venta, Captación..."
                                value={newPipelineName}
                                onChange={(e) => setNewPipelineName(e.target.value)}
                            />
                            <p className="text-sm text-muted-foreground mt-2">
                                Se crearán 6 etapas por defecto que podrás personalizar luego.
                            </p>
                        </div>
                        <DialogFooter>
                            <Button variant="outline" onClick={() => setIsCreateOpen(false)}>Cancelar</Button>
                            <Button onClick={handleCreate} disabled={createMutation.isPending}>
                                {createMutation.isPending ? 'Creando...' : 'Crear Ruta'}
                            </Button>
                        </DialogFooter>
                    </DialogContent>
                </Dialog>
            </div>



            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {pipelines.map((pipeline) => (
                    <div
                        key={pipeline.id}
                        className="group relative flex flex-col justify-between rounded-lg border p-6 hover:border-primary transition-colors bg-card"
                    >
                        <div className="space-y-2">
                            <div className="flex items-center justify-between">
                                <Layout className="h-5 w-5 text-muted-foreground" />
                                {pipeline.is_default && <Badge variant="secondary">Por Defecto</Badge>}
                            </div>

                            {editingId === pipeline.id ? (
                                <div className="flex items-center gap-2 mt-2">
                                    <Input
                                        value={editName}
                                        onChange={(e) => setEditName(e.target.value)}
                                        className="h-8"
                                    />
                                    <Button size="icon" variant="ghost" className="h-8 w-8 text-green-600" onClick={saveEdit}>
                                        <Check className="h-4 w-4" />
                                    </Button>
                                    <Button size="icon" variant="ghost" className="h-8 w-8 text-red-600" onClick={() => setEditingId(null)}>
                                        <X className="h-4 w-4" />
                                    </Button>
                                </div>
                            ) : (
                                <h3 className="font-semibold text-lg">{pipeline.name}</h3>
                            )}

                            <p className="text-sm text-muted-foreground line-clamp-2">
                                {pipeline.description || 'Sin descripción'}
                            </p>
                        </div>

                        <div className="mt-6 flex items-center gap-2">
                            <Button variant="outline" className="w-full" asChild>
                                <a href={`/settings/pipelines/${pipeline.id}`}>
                                    <Settings2 className="mr-2 h-4 w-4" />
                                    Configurar Etapas
                                </a>
                            </Button>

                            <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => startEdit(pipeline)}
                            >
                                <Pencil className="h-4 w-4 text-muted-foreground" />
                            </Button>

                            <Button
                                variant="ghost"
                                size="icon"
                                className="text-red-500 hover:text-red-600 hover:bg-red-50"
                                onClick={() => setDeleteId(pipeline.id)}
                            >
                                <Trash2 className="h-4 w-4" />
                            </Button>
                        </div>
                    </div>
                ))}
            </div>

            <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>¿Estás seguro?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Esta acción no se puede deshacer. Esto eliminará permanentemente la ruta de lead y todas sus etapas.
                            Si tiene tratos activos, no podrás eliminarla hasta moverlos o borrarlos.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                            className="bg-red-600 hover:bg-red-700"
                            onClick={() => deleteId && deleteMutation.mutate(deleteId)}
                        >
                            Eliminar
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}
