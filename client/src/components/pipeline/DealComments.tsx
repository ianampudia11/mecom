import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/use-auth';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { MessageSquare, Send, Edit2, Trash2, X } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
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

interface Comment {
    id: number;
    dealId: number;
    userId: number;
    comment: string;
    createdAt: string;
    updatedAt: string;
    username: string;
    userFullName: string;
    userEmail: string;
}

interface DealCommentsProps {
    dealId: number;
}

export default function DealComments({ dealId }: DealCommentsProps) {
    const { toast } = useToast();
    const { user } = useAuth();
    const queryClient = useQueryClient();
    const [newComment, setNewComment] = useState('');
    const [editingComment, setEditingComment] = useState<number | null>(null);
    const [editText, setEditText] = useState('');
    const [commentToDelete, setCommentToDelete] = useState<number | null>(null);

    // Fetch comments
    const { data: comments = [], isLoading, error } = useQuery<Comment[]>({
        queryKey: [`/api/deals/${dealId}/comments`],
        queryFn: async () => {
            try {
                const res = await apiRequest('GET', `/api/deals/${dealId}/comments`);
                if (!res.ok) {
                    console.error('Failed to fetch comments:', res.status);
                    return [];
                }
                const data = await res.json();
                return Array.isArray(data) ? data : [];
            } catch (err) {
                console.error('Error in comments query:', err);
                return [];
            }
        },
        retry: false,
    });

    // Create comment mutation
    const createCommentMutation = useMutation({
        mutationFn: async (comment: string) => {
            const res = await apiRequest('POST', `/api/deals/${dealId}/comments`, { comment });
            if (!res.ok) throw new Error('Failed to create comment');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/comments`] });
            setNewComment('');
            toast({
                title: 'Comentario agregado',
                description: 'Tu comentario ha sido publicado.',
            });
        },
        onError: () => {
            toast({
                title: 'Error',
                description: 'No se pudo agregar el comentario.',
                variant: 'destructive',
            });
        },
    });

    // Update comment mutation
    const updateCommentMutation = useMutation({
        mutationFn: async ({ commentId, comment }: { commentId: number; comment: string }) => {
            const res = await apiRequest('PUT', `/api/comments/${commentId}`, { comment });
            if (!res.ok) throw new Error('Failed to update comment');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/comments`] });
            setEditingComment(null);
            setEditText('');
            toast({
                title: 'Comentario actualizado',
                description: 'Los cambios han sido guardados.',
            });
        },
    });

    // Delete comment mutation
    const deleteCommentMutation = useMutation({
        mutationFn: async (commentId: number) => {
            const res = await apiRequest('DELETE', `/api/comments/${commentId}`);
            if (!res.ok) throw new Error('Failed to delete comment');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/comments`] });
            setCommentToDelete(null);
            toast({
                title: 'Comentario eliminado',
                description: 'El comentario ha sido eliminado.',
            });
        },
    });

    const handleAddComment = () => {
        if (!newComment.trim()) return;
        createCommentMutation.mutate(newComment);
    };

    const handleStartEdit = (comment: Comment) => {
        setEditingComment(comment.id);
        setEditText(comment.comment);
    };

    const handleSaveEdit = (commentId: number) => {
        if (!editText.trim()) return;
        updateCommentMutation.mutate({ commentId, comment: editText });
    };

    const handleCancelEdit = () => {
        setEditingComment(null);
        setEditText('');
    };

    const canEditComment = (comment: Comment) => {
        return user?.id !== undefined && user?.id === comment.userId;
    };

    if (isLoading) {
        return <div className="text-sm text-gray-500">Cargando comentarios...</div>;
    }

    if (error) {
        return <div className="text-sm text-red-500">Error al cargar comentarios. Por favor intenta más tarde.</div>;
    }

    return (
        <div className="space-y-4">
            {/* Comments List */}
            {comments.length > 0 ? (
                <div className="space-y-3">
                    {comments.map((comment) => (
                        <div
                            key={comment.id}
                            className="group border rounded-lg p-4 hover:bg-gray-50 transition-colors"
                        >
                            {editingComment === comment.id ? (
                                <div className="space-y-3">
                                    <Textarea
                                        value={editText}
                                        onChange={(e) => setEditText(e.target.value)}
                                        className="min-h-[80px] resize-none"
                                        autoFocus
                                    />
                                    <div className="flex justify-end gap-2">
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            onClick={handleCancelEdit}
                                        >
                                            <X className="h-4 w-4 mr-1" />
                                            Cancelar
                                        </Button>
                                        <Button
                                            size="sm"
                                            onClick={() => handleSaveEdit(comment.id)}
                                            disabled={!editText.trim() || updateCommentMutation.isPending}
                                        >
                                            Guardar
                                        </Button>
                                    </div>
                                </div>
                            ) : (
                                <>
                                    <div className="flex items-start justify-between mb-2">
                                        <div className="flex items-center gap-2">
                                            <div className="h-8 w-8 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center text-white text-sm font-semibold">
                                                {(comment.userFullName || comment.username).charAt(0).toUpperCase()}
                                            </div>
                                            <div>
                                                <p className="text-sm font-medium text-gray-900">
                                                    {comment.userFullName || comment.username}
                                                </p>
                                                <p className="text-xs text-gray-500">
                                                    {formatDistanceToNow(new Date(comment.createdAt), { addSuffix: true })}
                                                    {comment.createdAt !== comment.updatedAt && ' (editado)'}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                    <p className="text-sm text-gray-700 whitespace-pre-wrap leading-relaxed">
                                        {comment.comment}
                                    </p>
                                </>
                            )}
                        </div>
                    ))}
                </div>
            ) : (
                <div className="text-center py-8 border-2 border-dashed rounded-lg">
                    <MessageSquare className="h-12 w-12 text-gray-400 mx-auto mb-2" />
                    <p className="text-sm text-gray-500">
                        No hay comentarios aún. ¡Sé el primero en comentar!
                    </p>
                </div>
            )}

            {/* Add Comment Form */}
            <div className="border-t pt-4">
                <div className="space-y-3">
                    <Textarea
                        placeholder="Escribe un comentario..."
                        value={newComment}
                        onChange={(e) => setNewComment(e.target.value)}
                        className="min-h-[80px] resize-none"
                        onKeyDown={(e) => {
                            if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
                                handleAddComment();
                            }
                        }}
                    />
                    <div className="flex justify-between items-center">
                        <span className="text-xs text-gray-500">
                            Presiona Ctrl+Enter para enviar
                        </span>
                        <Button
                            onClick={handleAddComment}
                            disabled={!newComment.trim() || createCommentMutation.isPending}
                        >
                            <Send className="h-4 w-4 mr-2" />
                            Comentar
                        </Button>
                    </div>
                </div>
            </div>

            {/* Delete Confirmation Dialog */}
            <AlertDialog
                open={commentToDelete !== null}
                onOpenChange={() => setCommentToDelete(null)}
            >
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>¿Eliminar comentario?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Esta acción no se puede deshacer. El comentario será eliminado permanentemente.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={() => commentToDelete && deleteCommentMutation.mutate(commentToDelete)}
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
