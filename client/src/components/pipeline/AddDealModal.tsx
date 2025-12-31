import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { z } from 'zod';
import { CalendarIcon, Plus, X, Home } from 'lucide-react';
import { apiRequest } from '@/lib/queryClient';
import { useToast } from '@/hooks/use-toast';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Form,
  FormControl,
  FormDescription,
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
  SelectValue,
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
import { Calendar } from '@/components/ui/calendar';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { ColoredTag } from '@/components/ui/colored-tag';
import { Check, Tag as TagIcon } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { Property } from '@shared/schema';

const addDealSchema = z.object({
  contactId: z.number().min(1, 'Please select a contact'),
  title: z.string().min(2, 'Title must be at least 2 characters'),
  stage: z.string().min(1, 'Please select a pipeline stage'),
  value: z.number().min(0).optional().nullable(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.date().optional().nullable(),
  assignedToUserId: z.number().optional().nullable(),
  description: z.string().optional().nullable(),
  tags: z.array(z.string()).default([]),
});

type AddDealFormValues = z.infer<typeof addDealSchema>;

interface AddDealModalProps {
  isOpen: boolean;
  onClose: () => void;
  pipelineId?: number;
}

export default function AddDealModal({ isOpen, onClose, pipelineId }: AddDealModalProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // Tag State
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState<string>('');
  const [showTagDropdown, setShowTagDropdown] = useState(false);

  // Property State
  const [selectedProperties, setSelectedProperties] = useState<Property[]>([]);
  const [showPropertyDropdown, setShowPropertyDropdown] = useState(false);

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

  const { data: pipelineStages = [] } = useQuery({
    queryKey: ['pipeline-stages', pipelineId],
    queryFn: async () => {
      const url = pipelineId
        ? `/api/pipelines/${pipelineId}/stages`
        : '/api/pipeline/stages';
      const res = await apiRequest('GET', url);
      const data = await res.json();
      return Array.isArray(data) ? data : [];
    },
    enabled: isOpen
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

  // Fetch properties (for linking)
  const { data: properties = [] } = useQuery({
    queryKey: ['/api/properties'],
    queryFn: () => apiRequest('GET', '/api/properties').then(res => res.json()),
    enabled: isOpen
  });

  const form = useForm<AddDealFormValues>({
    resolver: zodResolver(addDealSchema),
    defaultValues: {
      contactId: undefined, // Moved to top
      title: '',
      stage: '',
      value: null,
      priority: 'medium',
      dueDate: null,
      assignedToUserId: null,
      description: '',
      tags: [],
    },
  });

  useEffect(() => {
    if (pipelineStages.length > 0 && !form.getValues('stage')) {
      form.setValue('stage', pipelineStages[0].id.toString());
    }
  }, [pipelineStages, form]);

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

  // Logic to process linking properties sequentially
  const linkProperties = async (dealId: number) => {
    if (selectedProperties.length === 0) return;

    const promises = selectedProperties.map(prop =>
      apiRequest('POST', `/api/deals/${dealId}/properties`, { property_id: prop.id })
    );

    await Promise.all(promises);
  };

  const createDealMutation = useMutation({
    mutationFn: async (data: AddDealFormValues) => {
      const response = await apiRequest('POST', '/api/deals', data);
      return response.json(); // Returns created deal
    },
    onSuccess: async (newDeal) => {
      // Chain property linking
      try {
        await linkProperties(newDeal.id);
        toast({
          title: "Success",
          description: "Deal created and properties linked successfully",
        });
      } catch (err) {
        toast({
          title: "Deal Created",
          description: "Deal created but failed to link properties. Please verify.",
          variant: "default"
        });
      }

      queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
      resetForm();
      onClose();
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: `Failed to create deal: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const onSubmit = (values: AddDealFormValues) => {
    values.tags = selectedTags;
    createDealMutation.mutate(values);
  };

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
          <DialogTitle>Add New Deal</DialogTitle>
          <DialogDescription>Create a new deal for a contact.</DialogDescription>
        </DialogHeader>
        <ScrollArea className="flex-1 px-4 py-6 overflow-auto">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8 m-2">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

                {/* 1. CONTACT (Primary) */}
                <FormField
                  control={form.control}
                  name="contactId"
                  render={({ field }) => (
                    <FormItem className="md:col-span-2">
                      <FormLabel className="text-base font-semibold text-blue-900">Contact (Lead)</FormLabel>
                      <Select
                        onValueChange={(value) => field.onChange(value === 'none' ? null : parseInt(value))}
                        value={field.value?.toString() || undefined}
                      >
                        <FormControl>
                          <SelectTrigger className="h-11">
                            <SelectValue placeholder="Select a person..." />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent className="max-h-[200px]">
                          {contactsData?.contacts && Array.isArray(contactsData.contacts) ? (
                            contactsData.contacts.map((contact: any) => (
                              <SelectItem key={contact.id} value={contact.id.toString()}>
                                <div className="flex flex-col text-left">
                                  <span className="font-medium">{contact.fullName || contact.name || contact.phoneNumber}</span>
                                  {contact.email && <span className="text-xs text-gray-500">{contact.email}</span>}
                                </div>
                              </SelectItem>
                            ))
                          ) : <SelectItem value="none" disabled>No contacts available</SelectItem>}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                {/* 2. INTEREST / TITLE (Secondary) */}
                <FormField
                  control={form.control}
                  name="title"
                  render={({ field }) => (
                    <FormItem className="md:col-span-2">
                      <FormLabel>Interés / Búsqueda</FormLabel>
                      <FormControl>
                        <Input {...field} placeholder="Ej: Compra de Casa en Centro..." />
                      </FormControl>
                      <FormDescription className="text-xs">Describe what they are looking for.</FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                {/* 3. PROPERTIES (New) */}
                <FormItem className="md:col-span-2">
                  <FormLabel>Propiedades de Interés</FormLabel>
                  <Popover open={showPropertyDropdown} onOpenChange={setShowPropertyDropdown}>
                    <PopoverTrigger asChild>
                      <Button variant="outline" role="combobox" className="justify-between w-full font-normal">
                        {selectedProperties.length > 0 ? `${selectedProperties.length} propiedades seleccionadas` : "Seleccionar propiedades..."}
                        <Plus className="ml-2 h-4 w-4 opacity-50" />
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-[400px] p-0" align="start">
                      <Command>
                        <CommandInput placeholder="Search properties..." />
                        <CommandList>
                          <CommandEmpty>No properties found.</CommandEmpty>
                          <CommandGroup>
                            {properties.map((prop: Property) => {
                              const isSelected = selectedProperties.some(p => p.id === prop.id);
                              return (
                                <CommandItem
                                  key={prop.id}
                                  value={prop.name}
                                  onSelect={() => {
                                    if (isSelected) {
                                      setSelectedProperties(prev => prev.filter(p => p.id !== prop.id));
                                    } else {
                                      setSelectedProperties(prev => [...prev, prop]);
                                    }
                                  }}
                                >
                                  <Check className={cn("mr-2 h-4 w-4", isSelected ? "opacity-100" : "opacity-0")} />
                                  <div className="flex flex-col">
                                    <span>{prop.name}</span>
                                    <span className="text-xs text-muted-foreground">{prop.address || prop.city} - {prop.price ? `$${prop.price}` : 'N/A'}</span>
                                  </div>
                                </CommandItem>
                              );
                            })}
                          </CommandGroup>
                        </CommandList>
                      </Command>
                    </PopoverContent>
                  </Popover>

                  {/* Selected Properties Tags */}
                  {selectedProperties.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-2">
                      {selectedProperties.map(prop => (
                        <Badge key={prop.id} variant="secondary" className="pl-2 pr-1 py-1 flex items-center gap-1">
                          <Home className="h-3 w-3 text-gray-500" />
                          <span className="max-w-[150px] truncate">{prop.name}</span>
                          <Button variant="ghost" size="icon" className="h-4 w-4 ml-1 hover:bg-red-100 hover:text-red-600 rounded-full"
                            onClick={() => setSelectedProperties(prev => prev.filter(p => p.id !== prop.id))}>
                            <X className="h-3 w-3" />
                          </Button>
                        </Badge>
                      ))}
                    </div>
                  )}
                </FormItem>

                <FormField
                  control={form.control}
                  name="value"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Deal Value</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          placeholder="0.00"
                          onChange={(e) => {
                            const value = e.target.value === '' ? null : parseFloat(e.target.value);
                            field.onChange(value);
                          }}
                          value={field.value === null ? '' : field.value}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="stage"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Stage</FormLabel>
                      <Select
                        onValueChange={field.onChange}
                        defaultValue={field.value}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select stage" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {pipelineStages.map((stage: any) => (
                            <SelectItem key={stage.id} value={stage.id.toString()}>
                              {stage.name}
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
                  name="priority"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Priority</FormLabel>
                      <Select
                        onValueChange={field.onChange}
                        defaultValue={field.value}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select priority" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="low">Low</SelectItem>
                          <SelectItem value="medium">Medium</SelectItem>
                          <SelectItem value="high">High</SelectItem>
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
                    <FormItem className="flex flex-col">
                      <FormLabel>Due Date</FormLabel>
                      <Popover>
                        <PopoverTrigger asChild>
                          <FormControl>
                            <Button
                              variant={"outline"}
                              className={cn(
                                "pl-3 text-left font-normal",
                                !field.value && "text-muted-foreground"
                              )}
                            >
                              {field.value ? (
                                format(field.value, "PPP")
                              ) : (
                                <span>Pick a date</span>
                              )}
                              <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                            </Button>
                          </FormControl>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="start">
                          <Calendar
                            mode="single"
                            selected={field.value || undefined}
                            onSelect={field.onChange}
                            disabled={(date) =>
                              date < new Date(new Date().setHours(0, 0, 0, 0))
                            }
                            initialFocus
                          />
                        </PopoverContent>
                      </Popover>
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
                            <SelectValue placeholder="Assign to" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="unassigned">Unassigned</SelectItem>
                          {teamMembers.map((user: any) => (
                            <SelectItem key={user.id} value={user.id.toString()}>
                              {user.fullName || user.username}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormItem className="md:col-span-2">
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
                  <div className="flex flex-wrap gap-2 mt-2">
                    {selectedTags.map((tag) => (
                      <ColoredTag
                        key={tag}
                        name={tag}
                        onRemove={() => handleRemoveTag(tag)}
                        size="md"
                      />
                    ))}
                  </div>
                  <FormDescription>Click button to select or create tags</FormDescription>
                </FormItem>

                <FormField
                  control={form.control}
                  name="description"
                  render={({ field }) => (
                    <FormItem className="md:col-span-2">
                      <FormLabel>Description</FormLabel>
                      <FormControl>
                        <Textarea
                          {...field}
                          placeholder="Enter deal description"
                          className="min-h-[100px]"
                          value={field.value || ''}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </form>
          </Form>
        </ScrollArea>

        <div className="border-t border-border mt-2">
          <DialogFooter className="px-8 py-6 flex flex-row justify-end gap-3 sm:gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button variant="outline" className="btn-brand-primary"
              type="submit"
              disabled={createDealMutation.isPending}
              onClick={form.handleSubmit(onSubmit)}
            >
              {createDealMutation.isPending ? "Creating..." : "Create Deal"}
            </Button>
          </DialogFooter>
        </div>
      </DialogContent>
    </Dialog>
  );
}