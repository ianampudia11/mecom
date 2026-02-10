import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { useToast } from '@/hooks/use-toast';
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/components/ui/card';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
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
import { ColoredTag } from '@/components/ui/colored-tag';
import { Edit, Trash2, Loader2, Plus } from 'lucide-react';
import { Label } from '@/components/ui/label';

interface TagStats {
    tag: string;
    conversationCount: number;
    dealCount: number;
    contactCount: number;
    color?: string | null;
}


export function TagManagement() {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [showRenameDialog, setShowRenameDialog] = useState(false);
    const [showDeleteDialog, setShowDeleteDialog] = useState(false);
    const [showCreateDialog, setShowCreateDialog] = useState(false);
    const [selectedTag, setSelectedTag] = useState<TagStats | null>(null);
    const [newTagName, setNewTagName] = useState('');
    const [newTagColor, setNewTagColor] = useState('');
    const [createTagName, setCreateTagName] = useState('');
    const [createTagColor, setCreateTagColor] = useState('');

    // Fetch tag statistics
    const { data: tags = [], isLoading } = useQuery<TagStats[]>({
        queryKey: ['/api/tags/stats'],
        queryFn: async () => {
            const res = await apiRequest('GET', '/api/tags/stats');
            if (!res.ok) throw new Error('Failed to fetch tag statistics');
            return res.json();
        },
    });

    // Rename mutation
    const renameMutation = useMutation({
        mutationFn: async ({ oldTag, newName, color }: { oldTag: string; newName: string; color?: string }) => {
            const res = await apiRequest('PUT', `/api/tags/${encodeURIComponent(oldTag)}`, {
                newName,
                color,
            });
            if (!res.ok) throw new Error('Failed to rename tag');
            return res.json();
        },
        onSuccess: () => {
            toast({
                title: 'Tag renombrado',
                description: 'El tag ha sido renombrado exitosamente en todas partes.',
            });
            queryClient.invalidateQueries({ queryKey: ['/api/tags/stats'] });
            queryClient.invalidateQueries({ queryKey: ['/api/contacts/tags'] });
            setShowRenameDialog(false);
            setSelectedTag(null);
            setNewTagName('');
        },
        onError: (error: Error) => {
            toast({
                title: 'Error',
                description: error.message,
                variant: 'destructive',
            });
        },
    });

    // Delete mutation
    const deleteMutation = useMutation({
        mutationFn: async (tagName: string) => {
            const res = await apiRequest('DELETE', `/api/tags/${encodeURIComponent(tagName)}`);
            if (!res.ok) throw new Error('Failed to delete tag');
            return res.json();
        },
        onSuccess: () => {
            toast({
                title: 'Tag eliminado',
                description: 'El tag ha sido eliminado de todas las conversaciones y deals.',
            });
            queryClient.invalidateQueries({ queryKey: ['/api/tags/stats'] });
            queryClient.invalidateQueries({ queryKey: ['/api/contacts/tags'] });
            setShowDeleteDialog(false);
            setSelectedTag(null);
        },
        onError: (error: Error) => {
            toast({
                title: 'Error',
                description: error.message,
                variant: 'destructive',
            });
        },
    });

    // Create mutation
    const createMutation = useMutation({
        mutationFn: async ({ name, color }: { name: string, color?: string }) => {
            const res = await apiRequest('POST', '/api/tags', { name, color });
            if (!res.ok) {
                const error = await res.json();
                throw new Error(error.error || 'Failed to create tag');
            }
            return res.json();
        },
        onSuccess: () => {
            toast({
                title: 'Tag creado',
                description: 'El tag está ahora disponible para usar.',
            });
            queryClient.invalidateQueries({ queryKey: ['/api/tags/stats'] });
            queryClient.invalidateQueries({ queryKey: ['/api/contacts/tags'] });
            setShowCreateDialog(false);
            setCreateTagName('');
            setCreateTagColor('');
        },
        onError: (error: Error) => {
            toast({
                title: 'Error',
                description: error.message,
                variant: 'destructive',
            });
        },
    });

    const handleRename = (tag: TagStats) => {
        setSelectedTag(tag);
        setNewTagName(tag.tag);
        setNewTagColor(tag.color || '');
        setShowRenameDialog(true);
    };

    const handleDelete = (tag: TagStats) => {
        setSelectedTag(tag);
        setShowDeleteDialog(true);
    };

    const confirmRename = () => {
        if (!selectedTag || !newTagName.trim()) return;
        renameMutation.mutate({ oldTag: selectedTag.tag, newName: newTagName.trim(), color: newTagColor || undefined });
    };

    const confirmDelete = () => {
        if (!selectedTag) return;
        deleteMutation.mutate(selectedTag.tag);
    };

    const handleCreate = () => {
        setCreateTagName('');
        setCreateTagColor('');
        setShowCreateDialog(true);
    };

    const confirmCreate = () => {
        if (!createTagName.trim()) return;
        createMutation.mutate({ name: createTagName.trim(), color: createTagColor || undefined });
    };

    const getTotalUsage = (tag: TagStats) => {
        return tag.conversationCount + tag.dealCount + tag.contactCount;
    };


    const [searchQuery, setSearchQuery] = useState('');

    // Filter tags based on search query
    const filteredTags = tags.filter(tag =>
        tag.tag.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <>
            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <div>
                            <CardTitle>Gestión de Tags</CardTitle>
                            <CardDescription>
                                Administra todos tus tags: crea, renombra o elimina tags de conversaciones y deals
                            </CardDescription>
                        </div>
                        <Button onClick={handleCreate} size="sm">
                            <Plus className="h-4 w-4 mr-2" />
                            Crear Tag
                        </Button>
                    </div>
                    <div className="mt-4">
                        <Input
                            placeholder="Buscar tags..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="max-w-sm"
                        />
                    </div>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <div className="flex items-center justify-center p-8">
                            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                        </div>
                    ) : filteredTags.length === 0 ? (
                        <div className="text-center p-8 text-muted-foreground">
                            {searchQuery ? 'No se encontraron tags que coincidan con tu búsqueda' : 'No hay tags creados aún'}
                        </div>
                    ) : (
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Tag</TableHead>
                                    <TableHead className="text-center">Conversaciones</TableHead>
                                    <TableHead className="text-center">Deals</TableHead>
                                    <TableHead className="text-center">Contactos</TableHead>
                                    <TableHead className="text-center">Total</TableHead>
                                    <TableHead className="text-right">Acciones</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {filteredTags.map((tag) => (
                                    <TableRow key={tag.tag}>
                                        <TableCell>
                                            <ColoredTag name={tag.tag} color={tag.color || undefined} size="md" />
                                        </TableCell>
                                        <TableCell className="text-center">{tag.conversationCount}</TableCell>
                                        <TableCell className="text-center">{tag.dealCount}</TableCell>
                                        <TableCell className="text-center">{tag.contactCount}</TableCell>
                                        <TableCell className="text-center font-medium">
                                            {getTotalUsage(tag)}
                                        </TableCell>
                                        <TableCell className="text-right">
                                            <div className="flex justify-end gap-2">
                                                <Button
                                                    variant="ghost"
                                                    size="sm"
                                                    onClick={() => handleRename(tag)}
                                                    disabled={renameMutation.isPending || deleteMutation.isPending}
                                                >
                                                    <Edit className="h-4 w-4" />
                                                </Button>
                                                <Button
                                                    variant="ghost"
                                                    size="sm"
                                                    onClick={() => handleDelete(tag)}
                                                    disabled={renameMutation.isPending || deleteMutation.isPending}
                                                >
                                                    <Trash2 className="h-4 w-4 text-red-500" />
                                                </Button>
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    )}
                </CardContent>
            </Card>

            {/* Rename Dialog */}
            <Dialog open={showRenameDialog} onOpenChange={setShowRenameDialog}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Renombrar Tag</DialogTitle>
                        <DialogDescription>
                            Este cambio se aplicará en todas las conversaciones y deals que usan este tag.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Label>Tag actual</Label>
                            {selectedTag && <ColoredTag name={selectedTag.tag} color={selectedTag.color || undefined} size="md" />}
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="newName">Nuevo nombre</Label>
                            <Input
                                id="newName"
                                value={newTagName}
                                onChange={(e) => setNewTagName(e.target.value)}
                                placeholder="Ingresa el nuevo nombre"
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter') {
                                        confirmRename();
                                    }
                                }}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="tagColor">Color (opcional)</Label>
                            <div className="flex gap-2 items-center">
                                <Input
                                    id="tagColor"
                                    type="color"
                                    value={newTagColor || '#808080'}
                                    onChange={(e) => setNewTagColor(e.target.value)}
                                    className="w-20 h-10 cursor-pointer"
                                />
                                {newTagColor && (
                                    <button
                                        onClick={() => setNewTagColor('')}
                                        className="text-sm text-muted-foreground hover:text-foreground"
                                    >
                                        Quitar color
                                    </button>
                                )}
                            </div>
                        </div>
                    </div>
                    <DialogFooter>
                        <Button
                            variant="outline"
                            onClick={() => setShowRenameDialog(false)}
                            disabled={renameMutation.isPending}
                        >
                            Cancelar
                        </Button>
                        <Button
                            onClick={confirmRename}
                            disabled={renameMutation.isPending || !newTagName.trim()}
                        >
                            {renameMutation.isPending && (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            )}
                            Renombrar
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>¿Eliminar este tag?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Esta acción eliminará el tag{' '}
                            {selectedTag && <ColoredTag name={selectedTag.tag} color={selectedTag.color || undefined} size="sm" />} de{' '}
                            {selectedTag && (
                                <>
                                    <strong>{selectedTag.conversationCount} conversaciones</strong>,{' '}
                                    <strong>{selectedTag.dealCount} deals</strong>, y{' '}
                                    <strong>{selectedTag.contactCount} contactos</strong>
                                </>
                            )}
                            . Esta acción no se puede deshacer.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel disabled={deleteMutation.isPending}>
                            Cancelar
                        </AlertDialogCancel>
                        <AlertDialogAction
                            onClick={confirmDelete}
                            disabled={deleteMutation.isPending}
                            className="bg-red-600 hover:bg-red-700"
                        >
                            {deleteMutation.isPending && (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            )}
                            Eliminar
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>

            {/* Create Tag Dialog */}
            <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Crear Nuevo Tag</DialogTitle>
                        <DialogDescription>
                            El tag estará disponible inmediatamente para usar en conversaciones y deals.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Label htmlFor="createName">Nombre del Tag</Label>
                            <Input
                                id="createName"
                                value={createTagName}
                                onChange={(e) => setCreateTagName(e.target.value)}
                                placeholder="Ingresa el nombre del tag"
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter') {
                                        confirmCreate();
                                    }
                                }}
                                autoFocus
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="createColor">Color (opcional)</Label>
                            <div className="flex gap-2 items-center">
                                <Input
                                    id="createColor"
                                    type="color"
                                    value={createTagColor || '#808080'}
                                    onChange={(e) => setCreateTagColor(e.target.value)}
                                    className="w-20 h-10 cursor-pointer"
                                />
                                {createTagColor && (
                                    <button
                                        onClick={() => setCreateTagColor('')}
                                        className="text-sm text-muted-foreground hover:text-foreground"
                                    >
                                        Quitar color
                                    </button>
                                )}
                            </div>
                        </div>
                        {createTagName.trim() && (
                            <div className="space-y-2">
                                <Label>Vista previa</Label>
                                <ColoredTag name={createTagName.trim()} color={createTagColor || undefined} size="md" />
                            </div>
                        )}
                    </div>
                    <DialogFooter>
                        <Button
                            variant="outline"
                            onClick={() => setShowCreateDialog(false)}
                            disabled={createMutation.isPending}
                        >
                            Cancelar
                        </Button>
                        <Button
                            onClick={confirmCreate}
                            disabled={createMutation.isPending || !createTagName.trim()}
                        >
                            {createMutation.isPending && (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            )}
                            Crear
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}
