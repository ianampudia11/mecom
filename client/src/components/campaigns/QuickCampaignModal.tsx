import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { useTranslation } from '@/hooks/use-translation';
import { Send, Loader2 } from 'lucide-react';
import { CollapsibleSection } from '@/components/ui/collapsible-section';

interface QuickCampaignModalProps {
    isOpen: boolean;
    onClose: () => void;
    selectedContactIds: number[];
    onSuccess?: () => void;
}

export function QuickCampaignModal({
    isOpen,
    onClose,
    selectedContactIds,
    onSuccess
}: QuickCampaignModalProps) {
    const [formData, setFormData] = useState({
        name: '',
        content: '',
        whatsappChannelType: 'unofficial' as const,
        messageType: 'text' as const,
        campaignType: 'immediate' as 'immediate' | 'scheduled',
        scheduledAt: '',
    });

    const [isSubmitting, setIsSubmitting] = useState(false);
    const { toast } = useToast();
    const { t } = useTranslation();

    const handleSubmit = async () => {
        // Validación básica
        if (!formData.name.trim()) {
            toast({
                title: t('common.error', 'Error'),
                description: 'El nombre de la campaña es requerido',
                variant: 'destructive'
            });
            return;
        }

        if (!formData.content.trim()) {
            toast({
                title: t('common.error', 'Error'),
                description: 'El mensaje es requerido',
                variant: 'destructive'
            });
            return;
        }

        if (formData.campaignType === 'scheduled' && !formData.scheduledAt) {
            toast({
                title: t('common.error', 'Error'),
                description: 'Debes seleccionar una fecha y hora para programar',
                variant: 'destructive'
            });
            return;
        }

        setIsSubmitting(true);

        try {
            // 1. Crear segmento temporal con los contactos seleccionados
            const segmentResponse = await fetch('/api/campaigns/segments', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: `Quick Campaign - ${formData.name}`,
                    description: 'Segmento creado automáticamente desde Quick Campaign',
                    criteria: {
                        contactIds: selectedContactIds,
                        excludedContactIds: []
                    }
                })
            });

            const segmentData = await segmentResponse.json();
            if (!segmentData.success) {
                throw new Error(segmentData.error || 'Error al crear segmento');
            }

            // 2. Crear campaña con el segmento
            const campaignPayload: any = {
                name: formData.name,
                content: formData.content,
                whatsappChannelType: formData.whatsappChannelType,
                messageType: formData.messageType,
                campaignType: formData.campaignType,
                segmentId: segmentData.data.id,
                status: 'draft'
            };

            if (formData.campaignType === 'scheduled' && formData.scheduledAt) {
                campaignPayload.scheduledAt = new Date(formData.scheduledAt).toISOString();
            }

            const campaignResponse = await fetch('/api/campaigns', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(campaignPayload)
            });

            const campaignData = await campaignResponse.json();
            if (!campaignData.success) {
                throw new Error(campaignData.error || 'Error al crear campaña');
            }

            // 3. Iniciar campaña inmediatamente si es tipo 'immediate'
            if (formData.campaignType === 'immediate') {
                const startResponse = await fetch(`/api/campaigns/${campaignData.data.id}/start`, {
                    method: 'POST'
                });

                const startData = await startResponse.json();
                if (!startData.success) {
                    throw new Error(startData.error || 'Error al iniciar campaña');
                }

                toast({
                    title: t('common.success', 'Éxito'),
                    description: `Campaña "${formData.name}" enviándose a ${selectedContactIds.length} contactos`
                });
            } else {
                toast({
                    title: t('common.success', 'Éxito'),
                    description: `Campaña "${formData.name}" programada exitosamente`
                });
            }

            // Reset form
            setFormData({
                name: '',
                content: '',
                whatsappChannelType: 'unofficial',
                messageType: 'text',
                campaignType: 'immediate',
                scheduledAt: '',
            });

            onClose();
            if (onSuccess) onSuccess();

        } catch (error) {
            console.error('Error creating quick campaign:', error);
            toast({
                title: t('common.error', 'Error'),
                description: error instanceof Error ? error.message : 'Error al crear la campaña',
                variant: 'destructive'
            });
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={onClose}>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Send className="h-5 w-5" />
                        Enviar Campaña a {selectedContactIds.length} contactos
                    </DialogTitle>
                </DialogHeader>

                <div className="space-y-4 py-4">
                    {/* Nombre de campaña */}
                    <div>
                        <Label htmlFor="campaign-name">Nombre de la campaña *</Label>
                        <Input
                            id="campaign-name"
                            placeholder="Ej: Seguimiento Enero 2026"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            disabled={isSubmitting}
                        />
                    </div>

                    {/* Mensaje */}
                    <div>
                        <Label htmlFor="campaign-message">Mensaje *</Label>
                        <Textarea
                            id="campaign-message"
                            placeholder="Escribe tu mensaje aquí... Usa {{name}}, {{email}}, {{phone}} para personalizar"
                            rows={6}
                            value={formData.content}
                            onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                            disabled={isSubmitting}
                        />
                        <p className="text-sm text-gray-500 mt-1">
                            Variables disponibles: {'{'}{'{'} name {'}'}{'}'}, {'{'}{'{'} email {'}'}{'}'}, {'{'}{'{'} phone {'}'}{'}'}, {'{'}{'{'} company {'}'}{'}'}
                        </p>
                    </div>

                    {/* Configuración avanzada (colapsable) */}
                    <CollapsibleSection
                        title="⚙️ Configuración avanzada (opcional)"
                        defaultOpen={false}
                    >
                        <div className="space-y-4">
                            {/* Programar envío */}
                            <div>
                                <Label htmlFor="campaign-schedule">Programar envío</Label>
                                <div className="flex gap-2 flex-col">
                                    <select
                                        className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                                        value={formData.campaignType}
                                        onChange={(e) => setFormData({
                                            ...formData,
                                            campaignType: e.target.value as 'immediate' | 'scheduled'
                                        })}
                                        disabled={isSubmitting}
                                    >
                                        <option value="immediate">Enviar ahora</option>
                                        <option value="scheduled">Programar para después</option>
                                    </select>

                                    {formData.campaignType === 'scheduled' && (
                                        <Input
                                            type="datetime-local"
                                            value={formData.scheduledAt}
                                            onChange={(e) => setFormData({ ...formData, scheduledAt: e.target.value })}
                                            disabled={isSubmitting}
                                            min={new Date().toISOString().slice(0, 16)}
                                        />
                                    )}
                                </div>
                            </div>
                        </div>
                    </CollapsibleSection>
                </div>

                <DialogFooter>
                    <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
                        Cancelar
                    </Button>
                    <Button
                        onClick={handleSubmit}
                        disabled={isSubmitting}
                        className="bg-green-600 hover:bg-green-700"
                    >
                        {isSubmitting ? (
                            <>
                                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                Enviando...
                            </>
                        ) : (
                            <>
                                <Send className="h-4 w-4 mr-2" />
                                {formData.campaignType === 'immediate' ? 'Enviar Ahora' : 'Programar Campaña'}
                            </>
                        )}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
