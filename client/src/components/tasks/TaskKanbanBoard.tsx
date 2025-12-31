import { useState, useMemo } from 'react';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { useTranslation } from '@/hooks/use-translation';
import { Loader2, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import TaskCard from './TaskCard';

interface Task {
    id: number;
    contactId: number | null;
    companyId: number;
    title: string;
    description: string | null;
    priority: 'low' | 'medium' | 'high' | 'urgent';
    status: 'not_started' | 'in_progress' | 'completed' | 'cancelled';
    dueDate: string | null;
    completedAt: string | null;
    assignedTo: string | null;
    category: string | null;
    tags: string[] | null;
    checklist: { id: string; text: string; completed: boolean }[] | null;
    backgroundColor: string | null;
    createdBy: number | null;
    updatedBy: number | null;
    createdAt: string;
    updatedAt: string;
}

interface TaskKanbanBoardProps {
    tasks: Task[];
    users: any[];
    onTaskUpdate: (taskId: number, updates: Partial<Task>) => void;
    onEditTask: (task: Task) => void;
    onDeleteTask: (task: Task) => void;
    isLoading?: boolean;
}

const COLUMNS = [
    { id: 'not_started', title: 'Pendiente', color: 'bg-gray-100 border-gray-200' },
    { id: 'in_progress', title: 'En Progreso', color: 'bg-blue-50 border-blue-200' },
    { id: 'completed', title: 'Completada', color: 'bg-green-50 border-green-200' },
    { id: 'cancelled', title: 'Cancelada', color: 'bg-red-50 border-red-200' },
] as const;

export default function TaskKanbanBoard({
    tasks,
    users,
    onTaskUpdate,
    onEditTask,
    onDeleteTask,
    isLoading
}: TaskKanbanBoardProps) {
    const { t } = useTranslation();

    const columns = useMemo(() => {
        const cols = {
            not_started: [] as Task[],
            in_progress: [] as Task[],
            completed: [] as Task[],
            cancelled: [] as Task[],
        };

        tasks.forEach(task => {
            if (cols[task.status]) {
                cols[task.status].push(task);
            } else {
                // Fallback for unknown statuses
                cols.not_started.push(task);
            }
        });

        return cols;
    }, [tasks]);

    const handleDragEnd = (result: any) => {
        const { destination, source, draggableId } = result;

        if (!destination) return;

        if (
            destination.droppableId === source.droppableId &&
            destination.index === source.index
        ) {
            return;
        }

        const taskId = parseInt(draggableId);
        const newStatus = destination.droppableId as Task['status'];

        onTaskUpdate(taskId, { status: newStatus });
    };

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-64">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="h-full overflow-x-auto overflow-y-hidden">
            <DragDropContext onDragEnd={handleDragEnd}>
                <div className="flex h-full gap-4 min-w-[1000px] p-1">
                    {COLUMNS.map(col => (
                        <div key={col.id} className="flex flex-col w-80 min-w-80 h-full rounded-lg bg-slate-50 border border-slate-200">
                            {/* Column Header */}
                            <div className={`p-3 border-b border-slate-100 flex justify-between items-center rounded-t-lg font-medium text-sm ${col.color}`}>
                                <div className="flex items-center gap-2">
                                    <span>{t(`tasks.status.${col.id}`, col.title)}</span>
                                    <span className="bg-white/50 text-slate-600 px-2 py-0.5 rounded-full text-xs">
                                        {columns[col.id as keyof typeof columns].length}
                                    </span>
                                </div>
                            </div>

                            {/* Droppable Area */}
                            <Droppable droppableId={col.id}>
                                {(provided, snapshot) => (
                                    <div
                                        ref={provided.innerRef}
                                        {...provided.droppableProps}
                                        className={`flex-1 p-2 overflow-y-auto space-y-2 transition-colors ${snapshot.isDraggingOver ? 'bg-slate-100/50' : ''
                                            }`}
                                    >
                                        {columns[col.id as keyof typeof columns].map((task, index) => (
                                            <Draggable key={task.id} draggableId={task.id.toString()} index={index}>
                                                {(provided, snapshot) => (
                                                    <div
                                                        ref={provided.innerRef}
                                                        {...provided.draggableProps}
                                                        {...provided.dragHandleProps}
                                                        className={snapshot.isDragging ? 'rotate-2 scale-105 z-50' : ''}
                                                        style={{ ...provided.draggableProps.style }}
                                                    >
                                                        <TaskCard
                                                            task={task}
                                                            users={users}
                                                            onEdit={onEditTask}
                                                            onDelete={onDeleteTask}
                                                        />
                                                    </div>
                                                )}
                                            </Draggable>
                                        ))}
                                        {provided.placeholder}
                                    </div>
                                )}
                            </Droppable>
                        </div>
                    ))}
                </div>
            </DragDropContext>
        </div>
    );
}
