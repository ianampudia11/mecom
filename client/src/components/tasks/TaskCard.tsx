import { useMemo } from 'react';
import { format, parseISO, isPast, isToday } from 'date-fns';
import { MoreHorizontal, Calendar, User, Flag, CheckCircle2 } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardFooter, CardHeader } from '@/components/ui/card';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/hooks/use-translation';

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

interface TaskCardProps {
    task: Task;
    onEdit: (task: Task) => void;
    onDelete: (task: Task) => void;
    users: any[]; // Team members for avatar lookup
}

export default function TaskCard({ task, onEdit, onDelete, users }: TaskCardProps) {
    const { t } = useTranslation();

    const priorityConfig = useMemo(() => {
        switch (task.priority) {
            case 'urgent': return { color: 'text-red-600 bg-red-50 border-red-200', icon: Flag };
            case 'high': return { color: 'text-orange-600 bg-orange-50 border-orange-200', icon: Flag };
            case 'medium': return { color: 'text-yellow-600 bg-yellow-50 border-yellow-200', icon: Flag };
            case 'low': return { color: 'text-blue-600 bg-blue-50 border-blue-200', icon: Flag };
            default: return { color: 'text-gray-600 bg-gray-50 border-gray-200', icon: Flag };
        }
    }, [task.priority]);

    const assignee = useMemo(() => {
        if (!task.assignedTo) return null;
        return users.find(u => u.email === task.assignedTo);
    }, [task.assignedTo, users]);

    const dueDateStatus = useMemo(() => {
        if (!task.dueDate) return null;
        const date = parseISO(task.dueDate);
        if (task.status === 'completed') return 'completed';
        if (isPast(date) && !isToday(date)) return 'overdue';
        if (isToday(date)) return 'due-today';
        return 'upcoming';
    }, [task.dueDate, task.status]);

    const PriorityIcon = priorityConfig.icon;

    return (
        <Card className="shadow-sm hover:shadow-md transition-shadow group cursor-grab active:cursor-grabbing border-l-4" style={{ borderLeftColor: getPriorityColor(task.priority) }}>
            <CardContent className="p-3 space-y-2">
                <div className="flex justify-between items-start gap-2">
                    <Badge variant="outline" className={cn("text-[10px] px-1.5 py-0 h-5 font-normal uppercase tracking-wider", priorityConfig.color)}>
                        {t(`tasks.priority.${task.priority}`, task.priority)}
                    </Badge>

                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-6 w-6 -mr-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                <MoreHorizontal className="h-3 w-3" />
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => onEdit(task)}>
                                {t('common.edit', 'Editar')}
                            </DropdownMenuItem>
                            <DropdownMenuItem className="text-destructive focus:text-destructive" onClick={() => onDelete(task)}>
                                {t('common.delete', 'Eliminar')}
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>

                <h3 className="font-medium text-sm leading-tight line-clamp-2">
                    {task.title}
                </h3>

                {task.tags && task.tags.length > 0 && (
                    <div className="flex flex-wrap gap-1">
                        {task.tags.slice(0, 3).map((tag, i) => (
                            <span key={i} className="text-[10px] bg-slate-100 text-slate-600 px-1 rounded">
                                #{tag}
                            </span>
                        ))}
                    </div>
                )}
            </CardContent>

            <CardFooter className="p-3 pt-0 flex justify-between items-center text-xs text-muted-foreground">
                <div className="flex items-center gap-2">
                    {assignee ? (
                        <TooltipProvider>
                            <Tooltip>
                                <TooltipTrigger>
                                    <Avatar className="h-5 w-5">
                                        <AvatarImage src={assignee.avatarUrl} />
                                        <AvatarFallback className="text-[9px] bg-primary/10 text-primary">
                                            {assignee.fullName?.substring(0, 2).toUpperCase() || '??'}
                                        </AvatarFallback>
                                    </Avatar>
                                </TooltipTrigger>
                                <TooltipContent>
                                    <p>{assignee.fullName}</p>
                                </TooltipContent>
                            </Tooltip>
                        </TooltipProvider>
                    ) : (
                        <TooltipProvider>
                            <Tooltip>
                                <TooltipTrigger>
                                    <div className="h-5 w-5 rounded-full bg-gray-100 border border-dashed border-gray-300 flex items-center justify-center">
                                        <User className="h-3 w-3 text-gray-400" />
                                    </div>
                                </TooltipTrigger>
                                <TooltipContent>
                                    <p>{t('tasks.unassigned', 'Sin asignar')}</p>
                                </TooltipContent>
                            </Tooltip>
                        </TooltipProvider>
                    )}
                </div>

                {task.dueDate && (
                    <div className={cn(
                        "flex items-center gap-1",
                        dueDateStatus === 'overdue' && "text-red-500 font-medium",
                        dueDateStatus === 'due-today' && "text-orange-500 font-medium",
                        dueDateStatus === 'completed' && "text-green-600"
                    )}>
                        <Calendar className="h-3 w-3" />
                        <span>{format(parseISO(task.dueDate), 'MMM d')}</span>
                    </div>
                )}

                {task.checklist && task.checklist.length > 0 && (
                    <div className="flex items-center gap-1 text-muted-foreground">
                        <CheckCircle2 className="h-3 w-3" />
                        <span>
                            {task.checklist.filter(i => i.completed).length}/{task.checklist.length}
                        </span>
                    </div>
                )}
            </CardFooter>
        </Card>
    );
}

function getPriorityColor(priority: string) {
    switch (priority) {
        case 'urgent': return '#dc2626'; // red-600
        case 'high': return '#ea580c'; // orange-600
        case 'medium': return '#ca8a04'; // yellow-600
        case 'low': return '#2563eb'; // blue-600
        default: return '#9ca3af'; // gray-400
    }
}
