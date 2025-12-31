import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { z } from 'zod';
import { Plus, X, Home } from 'lucide-react';
import { Deal, Property } from '@shared/schema';
import { apiRequest } from '@/lib/queryClient';
import { useToast } from '@/hooks/use-toast';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage
} from '@/components/ui/form';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from '@/components/ui/select';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from '@/components/ui/command';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { ColoredTag } from '@/components/ui/colored-tag';
import { Check, Tag as TagIcon } from 'lucide-react';
import { formatDistanceToNow, format } from 'date-fns';
import { es } from 'date-fns/locale';
import { cn } from '@/lib/utils';

// ... query code ...

const editDealSchema = z.object({
  title: z.string().min(2, 'Title must be at least 2 characters'),
  stageId: z.string().min(1, 'Please select a pipeline stage'),
  value: z.number().min(0).optional().nullable(),
  contactId: z.number().min(1, 'Please select a contact'),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.date().optional().nullable(),
  assignedToUserId: z.number().optional().nullable(),
  description: z.string().optional().nullable(),
  tags: z.array(z.string()).default([]),
});

type EditDealFormValues = z.infer<typeof editDealSchema>;

interface EditDealModalProps {
  deal: Deal | null;
  isOpen: boolean;
  onClose: () => void;
  pipelineId?: number;
}

export default function EditDealModal({ deal, isOpen, onClose, pipelineId }: EditDealModalProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState<string>('');
  const [showTagDropdown, setShowTagDropdown] = useState(false);

  // Property State
  const [selectedProperties, setSelectedProperties] = useState<Property[]>([]);
  const [showPropertyDropdown, setShowPropertyDropdown] = useState(false);

  // State for the selected pipeline (to filter stages)
  const [activePipelineId, setActivePipelineId] = useState<number | undefined>(pipelineId);

  // Fetch all pipelines for the selector
  const { data: pipelines = [] } = useQuery({
    queryKey: ['/api/pipelines'],
    queryFn: () => apiRequest('GET', '/api/pipelines').then(res => res.json()),
    enabled: isOpen
  });

  // Update activePipelineId when prop changes or we have deal data
  useEffect(() => {
    if (pipelineId) setActivePipelineId(pipelineId);
  }, [pipelineId]);

  const { data: contactsData } = useQuery({
    queryKey: ['/api/contacts'],
    queryFn: () => apiRequest('GET', '/api/contacts')
      .then(res => res.json()),
  });

  const { data: teamMembers = [] } = useQuery({
    queryKey: ['/api/team-members'],
    queryFn: () => apiRequest('GET', '/api/team-members')
      .then(res => res.json()),
  });

  // Fetch stages for the ACTIVE pipeline
  const { data: pipelineStages = [] } = useQuery({
    queryKey: ['pipeline-stages', activePipelineId],
    queryFn: async () => {
      if (!activePipelineId) return [];
      const res = await apiRequest('GET', `/api/pipelines/${activePipelineId}/stages`);
      return res.json();
    },
    enabled: isOpen && !!activePipelineId
  });

  // Fetch available tags
  const { data: availableTags = [] } = useQuery({
    queryKey: ['/api/contacts/tags'],
    queryFn: async () => {
      const res = await fetch('/api/contacts/tags');
      if (!res.ok) return [];
      const data = await res.json();
      return Array.isArray(data) ? data : [];
    },
    staleTime: 60000,
    enabled: isOpen
  });

  // Fetch properties
  const { data: properties = [] } = useQuery({
    queryKey: ['/api/properties'],
    queryFn: () => apiRequest('GET', '/api/properties').then(res => res.json()),
    enabled: isOpen
  });

  // Fetch deal's existing properties
  const { data: dealProperties = [] } = useQuery({
    queryKey: ['/api/deals', deal?.id, 'properties'],
    queryFn: () => apiRequest('GET', `/api/deals/${deal?.id}/properties`).then(res => res.json()),
    enabled: !!deal?.id && isOpen
  });

  const { data: activities = [] } = useQuery({
    queryKey: ['/api/deals', deal?.id, 'activities'],
    queryFn: async () => {
      try {
        const res = await fetch(`/api/deals/${deal?.id}/activities`, {
          credentials: 'include',
        });
        if (res.ok) return res.json();
        return [];
      } catch (error) {
        console.warn('Failed to fetch deal activities:', error);
        return [];
      }
    },
    enabled: !!deal?.id && isOpen
  });

  const form = useForm<EditDealFormValues>({
    resolver: zodResolver(editDealSchema),
    defaultValues: {
      title: '',
      stageId: '',
      value: null,
      contactId: undefined,
      priority: 'medium',
      dueDate: null,
      assignedToUserId: null,
      description: '',
      tags: [],
    },
  });

  useEffect(() => {
    if (deal && isOpen) {
      form.reset({
        title: deal.title || '',
        stageId: deal.stageId?.toString() || '',
        value: deal.value || null,
        contactId: deal.contactId || undefined,
        priority: deal.priority || 'medium',
        dueDate: deal.dueDate ? new Date(deal.dueDate) : null,
        assignedToUserId: deal.assignedToUserId || null,
        description: deal.description || '',
        tags: deal.tags || [],
      });
      setSelectedTags(deal.tags || []);
    }
  }, [deal, isOpen, form]);

  useEffect(() => {
    if (dealProperties && dealProperties.length > 0) {
      setSelectedProperties(dealProperties);
    }
  }, [dealProperties]);

  const resetForm = () => {
    form.reset();
    setSelectedTags([]);
    setTagInput('');
    setSelectedProperties([]);
  };

  const handleAddTag = () => {
    if (tagInput.trim() && !selectedTags.includes(tagInput.trim())) {
      const newTags = [...selectedTags, tagInput.trim()];
      setSelectedTags(newTags);
      form.setValue('tags', newTags);
      setTagInput('');
    }
  };

  const handleRemoveTag = (tag: string) => {
    const newTags = selectedTags.filter(t => t !== tag);
    setSelectedTags(newTags);
    form.setValue('tags', newTags);
  };

  const updateDealMutation = useMutation({
    mutationFn: async (data: EditDealFormValues & { propertyIds?: number[] }) => {
      if (!deal) throw new Error('No deal to update');

      // 1. Update Deal Details
      const response = await apiRequest('PATCH', `/api/deals/${deal.id}`, data);

      // 2. Sync Properties
      // dealProperties is the initial list from server
      const currentIds = new Set(dealProperties.map((p: any) => p.id));
      const newIds = new Set(selectedProperties.map(p => p.id));

      const toAdd = selectedProperties.filter(p => !currentIds.has(p.id));
      const toRemove = dealProperties.filter((p: any) => !newIds.has(p.id));

      const propertyPromises = [];

      for (const p of toAdd) {
        propertyPromises.push(apiRequest('POST', `/api/deals/${deal.id}/properties`, { property_id: p.id }));
      }

      for (const p of toRemove) {
        propertyPromises.push(apiRequest('DELETE', `/api/deals/${deal.id}/properties/${p.id}`));
      }

      await Promise.all(propertyPromises);

      return response.json();
    },
    onSuccess: () => {
      toast({
        title: "Success",
        description: "Deal has been updated",
      });
      queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
      // Also invalidate properties for this deal
      queryClient.invalidateQueries({ queryKey: ['/api/deals', deal?.id, 'properties'] });
      queryClient.invalidateQueries({ queryKey: ['deal-properties', deal?.id] });

      resetForm();
      onClose();
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: `Failed to update deal: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const onSubmit = (values: EditDealFormValues) => {
    const submitData = {
      ...values,
      tags: selectedTags,
      // propertyIds is technically ignored by PATCH but we pass it for consistency or if backend changes
      propertyIds: selectedProperties.map(p => p.id)
    };
    updateDealMutation.mutate(submitData);
  };

  const contacts = contactsData?.contacts || [];

  return (
    <Dialog open={isOpen} onOpenChange={(open) => {
      if (!open) {
        onClose();
      }
      if (open) {
        resetForm();
      }
    }}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] md:max-h-[80vh] p-0 flex flex-col">
        <DialogHeader className="px-8 pt-6 pb-4">
          <DialogTitle>Edit Deal</DialogTitle>
          <DialogDescription>Update the deal information</DialogDescription>
        </DialogHeader>
        <ScrollArea className="flex-1 px-4 py-6 overflow-auto">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8 m-2">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <FormField
                  control={form.control}
                  name="title"
                  render={({ field }) => (
                    <FormItem className="md:col-span-2">
                      <FormLabel>Deal Title</FormLabel>
                      <FormControl>
                        <Input {...field} placeholder="Enter deal title" />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="contactId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Contact</FormLabel>
                      <Select onValueChange={(value) => field.onChange(parseInt(value))} value={field.value?.toString() || undefined}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select a contact" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {contacts.map((contact: any) => (
                            <SelectItem key={contact.id} value={contact.id.toString()}>
                              {contact.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                {/* PROPERTIES (Multi-select) */}
                <div className="flex flex-col space-y-2 md:col-span-2">
                  <FormLabel>Linked Properties</FormLabel>
                  <div className="flex flex-wrap gap-2 mb-2 min-h-[32px] p-2 border rounded-md bg-gray-50/50">
                    {selectedProperties.length === 0 && (
                      <span className="text-sm text-gray-400 italic">No properties linked</span>
                    )}
                    {selectedProperties.map(property => (
                      <Badge key={property.id} variant="secondary" className="flex items-center gap-1 bg-white border-blue-200 text-blue-700">
                        <Home className="h-3 w-3" />
                        {property.name}
                        <button
                          type="button"
                          onClick={() => setSelectedProperties(prev => prev.filter(p => p.id !== property.id))}
                          className="ml-1 hover:text-red-500 focus:outline-none"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </Badge>
                    ))}
                  </div>

                  <Popover open={showPropertyDropdown} onOpenChange={setShowPropertyDropdown}>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        role="combobox"
                        aria-expanded={showPropertyDropdown}
                        className="w-full justify-between"
                      >
                        <span className="flex items-center gap-2 text-gray-600">
                          <Plus className="h-4 w-4" />
                          Link Property
                        </span>
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-[400px] p-0" align="start">
                      <Command>
                        <CommandInput placeholder="Search properties..." />
                        <CommandList>
                          <CommandEmpty>No property found.</CommandEmpty>
                          <CommandGroup heading="Available Properties">
                            {properties
                              .filter((property: any) => !selectedProperties.some(p => p.id === property.id))
                              .map((property: any) => (
                                <CommandItem
                                  key={property.id}
                                  onSelect={() => {
                                    setSelectedProperties(prev => [...prev, property]);
                                    setShowPropertyDropdown(false);
                                  }}
                                >
                                  <div className="flex items-center">
                                    <Home className="mr-2 h-4 w-4 text-gray-400" />
                                    <div className="flex flex-col">
                                      <span>{property.name}</span>
                                      {property.location && (
                                        <span className="text-xs text-gray-400">{property.location}</span>
                                      )}
                                    </div>
                                    <Check
                                      className={cn(
                                        "ml-auto h-4 w-4",
                                        selectedProperties.some(p => p.id === property.id)
                                          ? "opacity-100"
                                          : "opacity-0"
                                      )}
                                    />
                                  </div>
                                </CommandItem>
                              ))}
                          </CommandGroup>
                        </CommandList>
                      </Command>
                    </PopoverContent>
                  </Popover>
                  <p className="text-[0.8rem] text-muted-foreground">
                    Link properties relevant to this deal.
                  </p>
                </div>

                {/* Pipeline Selector (Replacing Deal Value) */}
                <FormItem>
                  <FormLabel>Ruta (Pipeline)</FormLabel>
                  <Select
                    value={activePipelineId?.toString()}
                    onValueChange={(val) => {
                      const newId = parseInt(val);
                      setActivePipelineId(newId);
                      form.setValue('stageId', ''); // Reset stage when pipeline changes
                    }}
                  >
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Seleccionar ruta" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {pipelines.map((p: any) => (
                        <SelectItem key={p.id} value={p.id.toString()}>
                          {p.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </FormItem>

                <FormField
                  control={form.control}
                  name="stageId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Etapa</FormLabel>
                      <Select
                        onValueChange={field.onChange}
                        value={field.value || undefined}
                        disabled={!activePipelineId}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Seleccionar etapa" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {pipelineStages.map((stage: any) => (
                            <SelectItem key={stage.id} value={stage.id.toString()}>
                              <div className="flex items-center">
                                <div
                                  className="w-3 h-3 rounded-full mr-2"
                                  style={{ backgroundColor: stage.color }}
                                />
                                {stage.name}
                              </div>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                {/* Removed Priority Field to make space or keep columns balanced? 
                    User asked to replace Value field.
                    Original layout:
                    [ Pipeline Stage ] [ Value      ]
                    [ Priority       ] [ Assigned To]
                    
                    New Layout Plan:
                    [ Pipeline (New) ] [ Stage      ]
                    [ Priority       ] [ Assigned To] 
                */}

                <FormField
                  control={form.control}
                  name="priority"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Prioridad</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value || undefined}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Seleccionar prioridad" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="low">Baja</SelectItem>
                          <SelectItem value="medium">Media</SelectItem>
                          <SelectItem value="high">Alta</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />


                <FormField
                  control={form.control}
                  name="assignedToUserId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Assigned To</FormLabel>
                      <Select
                        onValueChange={(value) => field.onChange(value === 'unassigned' ? null : parseInt(value))}
                        value={field.value?.toString() || 'unassigned'}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select assignee" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="unassigned">Unassigned</SelectItem>
                          {teamMembers.map((member: any) => (
                            <SelectItem key={member.id} value={member.id.toString()}>
                              {member.fullName || member.username}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="dueDate"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Due Date</FormLabel>
                      <FormControl>
                        <Input
                          type="date"
                          {...field}
                          value={field.value ? format(field.value, 'yyyy-MM-dd') : ''}
                          onChange={(e) => field.onChange(e.target.value ? new Date(e.target.value) : null)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Enter deal description..."
                        className="resize-none"
                        rows={3}
                        {...field}
                        value={field.value || ''}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="space-y-2">
                <FormLabel>Tags</FormLabel>
                <Popover open={showTagDropdown} onOpenChange={setShowTagDropdown}>
                  <PopoverTrigger asChild>
                    <Button
                      type="button"
                      variant="outline"
                      role="combobox"
                      aria-expanded={showTagDropdown}
                      className="justify-between h-10 w-full"
                    >
                      Select tags...
                      <Plus className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-[300px] p-0" align="start">
                    <Command>
                      <CommandInput
                        placeholder="Search tags..."
                        value={tagInput}
                        onValueChange={setTagInput}
                      />
                      <CommandList>
                        <CommandEmpty>
                          {tagInput && (
                            <div
                              className="p-2 text-xs cursor-pointer hover:bg-accent flex items-center gap-2"
                              onClick={() => {
                                handleAddTag();
                                setShowTagDropdown(false);
                              }}
                            >
                              <Plus className="h-3 w-3" />
                              Create "{tagInput}"
                            </div>
                          )}
                        </CommandEmpty>

                        {selectedTags.length > 0 && (
                          <CommandGroup heading="Selected">
                            {selectedTags.map((tag) => (
                              <CommandItem
                                key={tag}
                                value={tag}
                                onSelect={() => {
                                  handleRemoveTag(tag);
                                }}
                                className="bg-accent/50"
                              >
                                <Check className="mr-2 h-4 w-4" />
                                <ColoredTag name={tag} size="sm" />
                              </CommandItem>
                            ))}
                          </CommandGroup>
                        )}

                        {availableTags.filter((tag: string) =>
                          !selectedTags.includes(tag) &&
                          tag.toLowerCase().includes(tagInput.toLowerCase())
                        ).length > 0 && (
                            <>
                              <CommandSeparator />
                              <CommandGroup heading="Available">
                                {availableTags
                                  .filter((tag: string) => !selectedTags.includes(tag))
                                  .filter((tag: string) => tag.toLowerCase().includes(tagInput.toLowerCase()))
                                  .map((tag: string) => (
                                    <CommandItem
                                      key={tag}
                                      value={tag}
                                      onSelect={() => {
                                        const newTags = [...selectedTags, tag];
                                        setSelectedTags(newTags);
                                        form.setValue('tags', newTags);
                                        setTagInput('');
                                      }}
                                    >
                                      <TagIcon className="mr-2 h-3.5 w-3.5 opacity-70" />
                                      {tag}
                                    </CommandItem>
                                  ))}
                              </CommandGroup>
                            </>
                          )}
                      </CommandList>
                    </Command>
                  </PopoverContent>
                </Popover>
                {selectedTags.length > 0 && (
                  <div className="flex flex-wrap gap-2 mt-2">
                    {selectedTags.map((tag, index) => (
                      <ColoredTag
                        key={index}
                        name={tag}
                        onRemove={() => handleRemoveTag(tag)}
                        size="md"
                      />
                    ))}
                  </div>
                )}
              </div>


              {/* History Section */}
              <div className="border-t pt-4 mt-6">
                <h4 className="text-sm font-medium mb-3 text-gray-900">Actividad Reciente</h4>
                <div className="space-y-3">
                  {/* Creation & Update timestamps */}
                  {deal && (
                    <div className="grid grid-cols-2 gap-4 text-xs text-gray-500 mb-4 bg-gray-50 p-2 rounded border">
                      <div>
                        <span className="block font-medium text-gray-700">Creado</span>
                        <span>{format(new Date(deal.createdAt), 'dd MMM yyyy HH:mm', { locale: es })}</span>
                      </div>
                      <div>
                        <span className="block font-medium text-gray-700">Última actualización</span>
                        <span>{format(new Date(deal.updatedAt), 'dd MMM yyyy HH:mm', { locale: es })}</span>
                      </div>
                    </div>
                  )}

                  {activities.length > 0 ? (
                    activities.slice(0, 10).map((activity: any) => (
                      <div key={activity.id} className="flex gap-3 text-sm">
                        <div className="mt-1.5 h-1.5 w-1.5 rounded-full bg-blue-500 shrink-0" />
                        <div className="flex-1">
                          <p className="text-gray-700">
                            {activity.content
                              .replace('Deal created', 'Trato creado')
                              .replace('Deal updated', 'Trato actualizado')
                              .replace('Deal moved to', 'Movido a etapa')
                              .replace('stage', '')
                              .replace('Deal', 'Trato')
                              .replace('updated', 'actualizado')
                            }
                          </p>
                          <p className="text-xs text-gray-400 mt-0.5">
                            {formatDistanceToNow(new Date(activity.createdAt), { addSuffix: true, locale: es })}
                          </p>
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-xs text-gray-400 italic">No hay actividad reciente registrada.</p>
                  )}
                </div>
              </div>

            </form>
          </Form>
        </ScrollArea>
        <DialogFooter className="px-8 py-4">
          <Button type="button" variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            type="submit"
            onClick={form.handleSubmit(onSubmit)}
            disabled={updateDealMutation.isPending}
          >
            {updateDealMutation.isPending ? 'Updating...' : 'Update Deal'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog >
  );
}

