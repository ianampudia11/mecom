import React, { memo, useState, useEffect } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useTranslation } from '@/hooks/use-translation';
import { Button } from '@/components/ui/button';
import { Bell, User, Users, MessageCircle } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';

export const NotifyUserNode = memo(({ data, isConnectable, id }: NodeProps) => {
    const { t } = useTranslation();
    const [message, setMessage] = useState(data.message || '');
    const [recipientType, setRecipientType] = useState(data.recipientType || 'lead_owner');
    const [selectedUserId, setSelectedUserId] = useState(data.selectedUserId || '');
    const [channel, setChannel] = useState(data.channel || 'auto');

    // Fetch users for selection
    const { data: users = [] } = useQuery<any[]>({
        queryKey: ['/api/users'],
        enabled: recipientType === 'specific_user',
        // We assume an endpoint /api/users exists or similar. 
        // Usually /api/users/company members or similar. 
        // Adapting query based on typical project structure.
    });

    // Update local state when data changes externally
    useEffect(() => {
        setMessage(data.message || '');
        setRecipientType(data.recipientType || 'lead_owner');
        setSelectedUserId(data.selectedUserId || '');
        setChannel(data.channel || 'auto');
    }, [data.message, data.recipientType, data.selectedUserId, data.channel]);

    const updateNodeData = (updates: any) => {
        // We need to access the flow's updateNodeData function. 
        // Usually accessed via context or passed in props if customized, 
        // but in this codebase (from previous `flow-builder.tsx` reads), 
        // we might need to use the useReactFlow hook or a passed handler.
        // Checking standard ReactFlow usage.

        // Actually, in `flow-builder.tsx`, `updateNodeData` is a helper function passed to many nodes 
        // or nodes use `useReactFlow` to update themselves.
        // Let's use `useReactFlow` pattern if possible, or expect `data.onChange`?
        // Looking at `TriggerNode` in `flow-builder.tsx` (Step 3689), it uses `updateNodeData` passed from parent 
        // OR `setNodes` via `useReactFlow`.

        // Let's dispatch a custom event or use the setNodes provided by useReactFlow
    };

    // Since we are in a separate file, we need access to the store or a callback.
    // Most nodes in this project seem to be defined INSIDE `flow-builder.tsx` initially? 
    // Step 3761 shows `import { AIAssistantNode } from ...` so external files are used.
    // I need to know how they update data.
    // `AIAssistantNode` likely uses `useReactFlow`.

    const { setNodes } = require('reactflow').useReactFlow();

    const handleUpdate = (updates: any) => {
        setNodes((nds: any[]) =>
            nds.map((node) => {
                if (node.id === id) {
                    return {
                        ...node,
                        data: { ...node.data, ...updates },
                    };
                }
                return node;
            })
        );
    };

    const handleMessageChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        const newVal = e.target.value;
        setMessage(newVal);
        handleUpdate({ message: newVal });
    };

    const handleRecipientTypeChange = (val: string) => {
        setRecipientType(val);
        handleUpdate({ recipientType: val });
    };

    const handleUserChange = (val: string) => {
        setSelectedUserId(val);
        handleUpdate({ selectedUserId: val });
    };

    const handleChannelChange = (val: string) => {
        setChannel(val);
        handleUpdate({ channel: val });
    };

    return (
        <Card className="w-[300px] shadow-lg border-l-4 border-l-orange-500">
            <Handle
                type="target"
                position={Position.Left}
                isConnectable={isConnectable}
                className="w-3 h-3 bg-slate-400"
            />

            <CardHeader className="p-3 bg-secondary/10">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                    <Bell className="h-4 w-4 text-orange-500" />
                    {t('flow_builder.nodes.notify_user.title', 'Notify User')}
                </CardTitle>
            </CardHeader>

            <CardContent className="p-3 space-y-3">
                <div className="space-y-1">
                    <Label className="text-xs">{t('flow_builder.nodes.notify_user.recipient', 'Recipient')}</Label>
                    <Select value={recipientType} onValueChange={handleRecipientTypeChange}>
                        <SelectTrigger className="h-8 text-xs">
                            <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="lead_owner">
                                <span className="flex items-center gap-2">
                                    <User className="h-3 w-3" />
                                    {t('flow_builder.nodes.notify_user.lead_owner', 'Lead Owner')}
                                </span>
                            </SelectItem>
                            <SelectItem value="specific_user">
                                <span className="flex items-center gap-2">
                                    <Users className="h-3 w-3" />
                                    {t('flow_builder.nodes.notify_user.specific_user', 'Specific User')}
                                </span>
                            </SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                {recipientType === 'specific_user' && (
                    <div className="space-y-1">
                        <Label className="text-xs">{t('flow_builder.nodes.notify_user.select_user', 'Select User')}</Label>
                        <Select value={selectedUserId} onValueChange={handleUserChange}>
                            <SelectTrigger className="h-8 text-xs">
                                <SelectValue placeholder="Select user..." />
                            </SelectTrigger>
                            <SelectContent>
                                {users.map((user: any) => (
                                    <SelectItem key={user.id} value={user.id.toString()}>
                                        {user.fullName || user.username}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                )}

                <div className="space-y-1">
                    <Label className="text-xs">{t('flow_builder.nodes.notify_user.channel', 'Notification Channel')}</Label>
                    <Select value={channel} onValueChange={handleChannelChange}>
                        <SelectTrigger className="h-8 text-xs">
                            <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="auto">
                                <span className="flex items-center gap-2">
                                    <Bell className="h-3 w-3" />
                                    {t('flow_builder.nodes.notify_user.channel_auto', 'Auto (User Preference)')}
                                </span>
                            </SelectItem>
                            <SelectItem value="whatsapp">
                                <span className="flex items-center gap-2">
                                    <MessageCircle className="h-3 w-3 text-green-500" />
                                    Whatsapp
                                </span>
                            </SelectItem>
                            <SelectItem value="email">
                                <span className="flex items-center gap-2">
                                    <Users className="h-3 w-3 text-blue-500" />
                                    Email
                                </span>
                            </SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                <div className="space-y-1">
                    <Label className="text-xs">{t('flow_builder.nodes.notify_user.message', 'Notification Message')}</Label>
                    <Textarea
                        value={message}
                        onChange={handleMessageChange}
                        className="text-xs min-h-[60px]"
                        placeholder="New lead assigned: {{contact.name}}"
                    />
                    <p className="text-[10px] text-muted-foreground">
                        Supports variables like {'{{contact.name}}'}
                    </p>
                </div>
            </CardContent>

            <Handle
                type="source"
                position={Position.Right}
                isConnectable={isConnectable}
                className="w-3 h-3 bg-slate-400"
            />
        </Card>
    );
});

NotifyUserNode.displayName = 'NotifyUserNode';
