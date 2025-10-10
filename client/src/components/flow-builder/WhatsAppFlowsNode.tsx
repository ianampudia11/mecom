import { CheckCircle, ChevronDown, ChevronUp, Copy, Eye, EyeOff, Loader2, MessageSquare, Play, Plus, Settings, Trash2, X, XCircle } from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';
import { Handle, Position, useReactFlow } from 'reactflow';
import { useFlowContext } from '../../pages/flow-builder';
import { useTranslation } from '@/hooks/use-translation';

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from "@/components/ui/select";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger
} from "@/components/ui/tooltip";
import { Textarea } from "@/components/ui/textarea";
import { cn } from '@/lib/utils';
import { standardHandleStyle } from './StyledHandle';


const FLOW_COMPONENTS = [

  { type: 'TextHeading', name: 'Heading', category: 'text', icon: '📄' },
  { type: 'TextSubheading', name: 'Subheading', category: 'text', icon: '📄' },
  { type: 'TextBody', name: 'Body Text', category: 'text', icon: '📄' },
  { type: 'TextCaption', name: 'Caption', category: 'text', icon: '📄' },
  { type: 'RichText', name: 'Rich Text', category: 'text', icon: '📝' },
  

  { type: 'TextInput', name: 'Text Input', category: 'input', icon: '📝' },
  { type: 'TextArea', name: 'Text Area', category: 'input', icon: '📝' },
  { type: 'DatePicker', name: 'Date Picker', category: 'input', icon: '📅' },
  { type: 'CalendarPicker', name: 'Calendar Picker', category: 'input', icon: '📅' },
  { type: 'Dropdown', name: 'Dropdown', category: 'input', icon: '⬇️' },
  

  { type: 'CheckboxGroup', name: 'Checkbox Group', category: 'selection', icon: '☑️' },
  { type: 'RadioButtonsGroup', name: 'Radio Buttons', category: 'selection', icon: '🔘' },
  { type: 'ChipsSelector', name: 'Chips Selector', category: 'selection', icon: '🏷️' },
  { type: 'OptIn', name: 'Opt In', category: 'selection', icon: '✅' },
  

  { type: 'Image', name: 'Image', category: 'media', icon: '🖼️' },
  { type: 'ImageCarousel', name: 'Image Carousel', category: 'media', icon: '🎠' },
  { type: 'MediaUpload', name: 'Media Upload', category: 'media', icon: '📤' },
  

  { type: 'Footer', name: 'Footer', category: 'navigation', icon: '⬇️' },
  { type: 'NavigationList', name: 'Navigation List', category: 'navigation', icon: '📋' },
  { type: 'EmbeddedLink', name: 'Embedded Link', category: 'navigation', icon: '🔗' },
  

  { type: 'If', name: 'Conditional', category: 'logic', icon: '❓' },
  { type: 'Switch', name: 'Switch', category: 'logic', icon: '🔀' }
];


const FLOW_ACTIONS = [
  { type: 'navigate', name: 'Navigate to Screen', icon: '➡️' },
  { type: 'complete', name: 'Complete Flow', icon: '✅' },
  { type: 'data_exchange', name: 'Data Exchange', icon: '🔄' },
  { type: 'update_data', name: 'Update Data', icon: '📝' },
  { type: 'open_url', name: 'Open URL', icon: '🔗' }
];


const FLOW_TEMPLATES = [
  {
    id: 'contact_form',
    name: 'Contact Form',
    description: 'Simple contact information collection',
    category: 'LEAD_GENERATION',
    screens: [
      {
        id: 'CONTACT_INFO',
        title: 'Contact Information',
        terminal: true,
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'TextHeading',
              text: 'Contact Information'
            },
            {
              type: 'TextBody',
              text: 'Please provide your contact details'
            },
            {
              type: 'TextInput',
              name: 'full_name',
              label: 'Full Name',
              required: true
            },
            {
              type: 'TextInput',
              name: 'email',
              label: 'Email Address',
              required: true,
              input_type: 'email'
            },
            {
              type: 'TextInput',
              name: 'phone',
              label: 'Phone Number',
              required: false,
              input_type: 'phone'
            },
            {
              type: 'Footer',
              label: 'Submit',
              'on-click-action': {
                name: 'complete',
                payload: {
                  contact_submitted: true
                }
              }
            }
          ]
        }
      }
    ]
  },
  {
    id: 'appointment_booking',
    name: 'Appointment Booking',
    description: 'Book appointments with date and time selection',
    category: 'APPOINTMENT_BOOKING',
    screens: [
      {
        id: 'SELECT_SERVICE',
        title: 'Select Service',
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'TextHeading',
              text: 'Book an Appointment'
            },
            {
              type: 'TextBody',
              text: 'Please select the service you need'
            },
            {
              type: 'RadioButtonsGroup',
              name: 'service_type',
              label: 'Service Type',
              'data-source': [
                { id: 'consultation', title: 'Consultation' },
                { id: 'support', title: 'Technical Support' },
                { id: 'demo', title: 'Product Demo' }
              ],
              required: true
            },
            {
              type: 'Footer',
              label: 'Next',
              'on-click-action': {
                name: 'navigate',
                next: { name: 'SELECT_DATE' }
              }
            }
          ]
        }
      },
      {
        id: 'SELECT_DATE',
        title: 'Select Date & Time',
        terminal: true,
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'TextHeading',
              text: 'Select Date & Time'
            },
            {
              type: 'DatePicker',
              name: 'appointment_date',
              label: 'Preferred Date',
              required: true
            },
            {
              type: 'Dropdown',
              name: 'appointment_time',
              label: 'Preferred Time',
              'data-source': [
                { id: '09:00', title: '9:00 AM' },
                { id: '10:00', title: '10:00 AM' },
                { id: '11:00', title: '11:00 AM' },
                { id: '14:00', title: '2:00 PM' },
                { id: '15:00', title: '3:00 PM' },
                { id: '16:00', title: '4:00 PM' }
              ],
              required: true
            },
            {
              type: 'TextArea',
              name: 'additional_notes',
              label: 'Additional Notes',
              required: false
            },
            {
              type: 'Footer',
              label: 'Book Appointment',
              'on-click-action': {
                name: 'complete',
                payload: {
                  appointment_booked: true
                }
              }
            }
          ]
        }
      }
    ]
  },
  {
    id: 'feedback_survey',
    name: 'Feedback Survey',
    description: 'Collect customer feedback and ratings',
    category: 'CUSTOMER_SUPPORT',
    screens: [
      {
        id: 'FEEDBACK_FORM',
        title: 'Feedback Survey',
        terminal: true,
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'TextHeading',
              text: 'Your Feedback Matters'
            },
            {
              type: 'TextBody',
              text: 'Please help us improve by sharing your experience'
            },
            {
              type: 'RadioButtonsGroup',
              name: 'satisfaction_rating',
              label: 'How satisfied are you with our service?',
              'data-source': [
                { id: 'very_satisfied', title: '😄 Very Satisfied' },
                { id: 'satisfied', title: '🙂 Satisfied' },
                { id: 'neutral', title: '😐 Neutral' },
                { id: 'dissatisfied', title: '🙁 Dissatisfied' },
                { id: 'very_dissatisfied', title: '😞 Very Dissatisfied' }
              ],
              required: true
            },
            {
              type: 'TextArea',
              name: 'feedback_comments',
              label: 'Additional Comments',
              placeholder: 'Tell us more about your experience...',
              required: false
            },
            {
              type: 'CheckboxGroup',
              name: 'improvement_areas',
              label: 'What can we improve?',
              'data-source': [
                { id: 'response_time', title: 'Response Time' },
                { id: 'product_quality', title: 'Product Quality' },
                { id: 'customer_service', title: 'Customer Service' },
                { id: 'pricing', title: 'Pricing' },
                { id: 'user_experience', title: 'User Experience' }
              ]
            },
            {
              type: 'Footer',
              label: 'Submit Feedback',
              'on-click-action': {
                name: 'complete',
                payload: {
                  feedback_submitted: true
                }
              }
            }
          ]
        }
      }
    ]
  },
  {
    id: 'lead_qualification',
    name: 'Lead Qualification',
    description: 'Qualify potential customers',
    category: 'LEAD_GENERATION',
    screens: [
      {
        id: 'COMPANY_INFO',
        title: 'Company Information',
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'TextHeading',
              text: 'Tell us about your company'
            },
            {
              type: 'TextInput',
              name: 'company_name',
              label: 'Company Name',
              required: true
            },
            {
              type: 'Dropdown',
              name: 'company_size',
              label: 'Company Size',
              'data-source': [
                { id: '1-10', title: '1-10 employees' },
                { id: '11-50', title: '11-50 employees' },
                { id: '51-200', title: '51-200 employees' },
                { id: '201-1000', title: '201-1000 employees' },
                { id: '1000+', title: '1000+ employees' }
              ],
              required: true
            },
            {
              type: 'Dropdown',
              name: 'industry',
              label: 'Industry',
              'data-source': [
                { id: 'technology', title: 'Technology' },
                { id: 'healthcare', title: 'Healthcare' },
                { id: 'finance', title: 'Finance' },
                { id: 'retail', title: 'Retail' },
                { id: 'manufacturing', title: 'Manufacturing' },
                { id: 'other', title: 'Other' }
              ],
              required: true
            },
            {
              type: 'Footer',
              label: 'Next',
              'on-click-action': {
                name: 'navigate',
                next: { name: 'REQUIREMENTS' }
              }
            }
          ]
        }
      },
      {
        id: 'REQUIREMENTS',
        title: 'Requirements',
        terminal: true,
        layout: {
          type: 'SingleColumnLayout',
          children: [
            {
              type: 'TextHeading',
              text: 'What are you looking for?'
            },
            {
              type: 'CheckboxGroup',
              name: 'requirements',
              label: 'Select all that apply',
              'data-source': [
                { id: 'automation', title: 'Process Automation' },
                { id: 'integration', title: 'System Integration' },
                { id: 'analytics', title: 'Analytics & Reporting' },
                { id: 'support', title: 'Customer Support' },
                { id: 'training', title: 'Training & Onboarding' }
              ]
            },
            {
              type: 'Dropdown',
              name: 'timeline',
              label: 'Implementation Timeline',
              'data-source': [
                { id: 'immediate', title: 'Immediate (< 1 month)' },
                { id: 'short_term', title: 'Short term (1-3 months)' },
                { id: 'medium_term', title: 'Medium term (3-6 months)' },
                { id: 'long_term', title: 'Long term (6+ months)' },
                { id: 'not_sure', title: 'Not sure yet' }
              ],
              required: true
            },
            {
              type: 'TextArea',
              name: 'additional_requirements',
              label: 'Additional Requirements',
              placeholder: 'Describe any specific needs or questions...',
              required: false
            },
            {
              type: 'Footer',
              label: 'Submit',
              'on-click-action': {
                name: 'complete',
                payload: {
                  lead_qualified: true
                }
              }
            }
          ]
        }
      }
    ]
  }
];


const ROUTING_MODELS = [
  { value: 'blocking', name: 'Blocking', description: 'User must complete current screen before proceeding' },
  { value: 'non_blocking', name: 'Non-blocking', description: 'User can navigate freely between screens' }
];

interface FlowScreen {
  id: string;
  title: string;
  terminal?: boolean;
  success?: boolean;
  layout: {
    type: 'SingleColumnLayout';
    children: FlowComponent[];
  };
  data?: Record<string, any>;
}

interface FlowComponent {
  type: string;
  [key: string]: any;
}

interface FlowJSON {
  version: string;
  routing_model?: Record<string, string[]>;
  data_api_version?: string;
  data_channel_uri?: string;
  screens: FlowScreen[];
}

interface WhatsAppFlowsNodeProps {
  id: string;
  data: {
    label: string;
    flowName?: string;
    flowId?: string;
    flowJSON?: FlowJSON;
    businessPhoneNumberId?: string;
    accessToken?: string;
    screens?: FlowScreen[];
    onDeleteNode?: (id: string) => void;
    onDuplicateNode?: (id: string) => void;
  };
  isConnectable: boolean;
}

export function WhatsAppFlowsNode({ id, data, isConnectable }: WhatsAppFlowsNodeProps) {
  const { t } = useTranslation();
  const [isEditing, setIsEditing] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  

  const [flowName, setFlowName] = useState(data.flowName || '');
  const [flowId, setFlowId] = useState(data.flowId || '');
  

  const [flowVersion, setFlowVersion] = useState('7.2');
  const [dataApiVersion, setDataApiVersion] = useState('3.0');
  const [dataChannelUri, setDataChannelUri] = useState('');
  const [routingModel, setRoutingModel] = useState<Record<string, string[]>>({});
  const [screens, setScreens] = useState<FlowScreen[]>(data.screens || []);
  

  const [selectedScreen, setSelectedScreen] = useState<string>('');
  const [selectedComponent, setSelectedComponent] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'design' | 'json' | 'preview' | 'settings'>('design');
  const [showAdvancedSettings, setShowAdvancedSettings] = useState(false);
  

  const [isTesting, setIsTesting] = useState(false);
  const [testResult, setTestResult] = useState<{
    success: boolean;
    data?: any;
    error?: string;
  } | null>(null);
  const [showTestResult, setShowTestResult] = useState(false);


  const [whatsappConnection, setWhatsappConnection] = useState<{
    businessPhoneNumberId: string;
    accessToken: string;
    isConfigured: boolean;
  }>({
    businessPhoneNumberId: '',
    accessToken: '',
    isConfigured: false
  });

  const { setNodes } = useReactFlow();
  const { onDeleteNode, onDuplicateNode } = useFlowContext();


  const fetchWhatsAppConnection = useCallback(async () => {
    try {

      const response = await fetch('/api/v1/channel-connections?type=whatsapp', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.ok) {
        const connections = await response.json();
        const whatsappConnection = connections.find((conn: any) => conn.channelType === 'whatsapp');
        
        if (whatsappConnection && whatsappConnection.status === 'active') {
          const connectionData = whatsappConnection.connectionData || {};
          setWhatsappConnection({
            businessPhoneNumberId: connectionData.phoneNumberId || connectionData.businessPhoneNumberId || '',
            accessToken: whatsappConnection.accessToken || '',
            isConfigured: !!(connectionData.phoneNumberId && whatsappConnection.accessToken)
          });
        } else {
          setWhatsappConnection({
            businessPhoneNumberId: '',
            accessToken: '',
            isConfigured: false
          });
        }
      } else {

        setWhatsappConnection({
          businessPhoneNumberId: '',
          accessToken: '',
          isConfigured: false
        });
      }
    } catch (error) {
      console.error('Failed to fetch WhatsApp connection:', error);
      setWhatsappConnection({
        businessPhoneNumberId: '',
        accessToken: '',
        isConfigured: false
      });
    }
  }, []);


  useEffect(() => {
    fetchWhatsAppConnection();
  }, [fetchWhatsAppConnection]);

  const updateNodeData = useCallback((updates: any) => {
    setNodes((nodes) =>
      nodes.map((node) => {
        if (node.id === id) {
          return {
            ...node,
            data: {
              ...node.data,
              ...updates
            }
          };
        }
        return node;
      })
    );
  }, [id, setNodes]);

  useEffect(() => {
    updateNodeData({
      flowName,
      flowId,
      businessPhoneNumberId: whatsappConnection.businessPhoneNumberId,
      accessToken: whatsappConnection.accessToken,
      screens,
      flowJSON: generateFlowJSON()
    });
  }, [
    updateNodeData,
    flowName,
    flowId,
    whatsappConnection.businessPhoneNumberId,
    whatsappConnection.accessToken,
    screens,
    flowVersion,
    dataApiVersion,
    dataChannelUri,
    routingModel
  ]);

  const generateFlowJSON = (): FlowJSON => {
    const flowJSON: FlowJSON = {
      version: flowVersion,
      screens: screens.length > 0 ? screens : [{
        id: 'WELCOME_SCREEN',
        title: 'Welcome',
        terminal: true,
        layout: {
          type: 'SingleColumnLayout',
          children: [{
            type: 'TextHeading',
            text: 'Welcome to our Flow!'
          }]
        }
      }]
    };

    if (dataApiVersion) {
      flowJSON.data_api_version = dataApiVersion;
    }

    if (dataChannelUri) {
      flowJSON.data_channel_uri = dataChannelUri;
    }

    if (Object.keys(routingModel).length > 0) {
      flowJSON.routing_model = routingModel;
    }

    return flowJSON;
  };

  const addScreen = () => {
    const newScreenId = `SCREEN_${screens.length + 1}`;
    const newScreen: FlowScreen = {
      id: newScreenId,
      title: `Screen ${screens.length + 1}`,
      terminal: screens.length === 0,
      layout: {
        type: 'SingleColumnLayout',
        children: []
      }
    };
    
    setScreens([...screens, newScreen]);
    setSelectedScreen(newScreenId);
  };

  const updateScreen = (screenId: string, updates: Partial<FlowScreen>) => {
    setScreens(screens.map(screen => 
      screen.id === screenId ? { ...screen, ...updates } : screen
    ));
  };

  const deleteScreen = (screenId: string) => {
    setScreens(screens.filter(screen => screen.id !== screenId));
    if (selectedScreen === screenId) {
      setSelectedScreen('');
    }
  };

  const addComponentToScreen = (screenId: string, componentType: string) => {
    const component: FlowComponent = {
      type: componentType
    };


    switch (componentType) {
      case 'TextHeading':
        component.text = 'Heading Text';
        break;
      case 'TextBody':
        component.text = 'Body text goes here...';
        break;
      case 'TextInput':
        component.name = 'text_input';
        component.label = 'Enter text';
        component.required = false;
        break;
      case 'DatePicker':
        component.name = 'date_picker';
        component.label = 'Select date';
        break;
      case 'Dropdown':
        component.name = 'dropdown';
        component.label = 'Select option';
        component['data-source'] = [];
        break;
      case 'Footer':
        component.label = 'Continue';
        component['on-click-action'] = {
          name: 'complete',
          payload: {}
        };
        break;
    }

    updateScreen(screenId, {
      layout: {
        type: 'SingleColumnLayout',
        children: [...(screens.find(s => s.id === screenId)?.layout.children || []), component]
      }
    });
  };

  const validateFlowJSON = (): { isValid: boolean; errors: string[] } => {
    const errors: string[] = [];

    if (!flowName.trim()) {
      errors.push('Flow name is required');
    }

    if (screens.length === 0) {
      errors.push('At least one screen is required');
    }

    screens.forEach((screen, index) => {
      if (!screen.id.trim()) {
        errors.push(`Screen ${index + 1}: ID is required`);
      }
      if (!screen.title.trim()) {
        errors.push(`Screen ${index + 1}: Title is required`);
      }
    });

    return {
      isValid: errors.length === 0,
      errors
    };
  };

  const testFlow = async () => {
    if (!whatsappConnection.isConfigured) {
      setTestResult({
        success: false,
        error: 'WhatsApp Business connection is not configured. Please set up your WhatsApp channel first.'
      });
      setShowTestResult(true);
      return;
    }

    const validation = validateFlowJSON();
    if (!validation.isValid) {
      setTestResult({
        success: false,
        error: validation.errors.join(', ')
      });
      setShowTestResult(true);
      return;
    }

    setIsTesting(true);
    setTestResult(null);
    setShowTestResult(true);

    try {
      const flowJSON = generateFlowJSON();
      


      const response = await fetch(`https://graph.facebook.com/v17.0/${whatsappConnection.businessPhoneNumberId}/flows`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${whatsappConnection.accessToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: flowName,
          flow_json: flowJSON,
          categories: ['SIGN_UP']
        })
      });

      if (response.ok) {
        const result = await response.json();
        setTestResult({
          success: true,
          data: result
        });
      } else {
        const error = await response.json();
        setTestResult({
          success: false,
          error: error.error?.message || 'Failed to create flow'
        });
      }
    } catch (error: any) {
      setTestResult({
        success: false,
        error: error.message || 'Connection failed'
      });
    } finally {
      setIsTesting(false);
    }
  };

  const renderScreenDesigner = () => {
    const currentScreen = screens.find(s => s.id === selectedScreen);
    if (!currentScreen) return null;

    return (
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h4 className="text-sm font-medium">Screen: {currentScreen.title}</h4>
          <Button
            variant="outline"
            size="sm"
            onClick={() => deleteScreen(currentScreen.id)}
            className="text-red-600 hover:text-red-700"
          >
            <Trash2 className="h-3 w-3" />
          </Button>
        </div>

        <div className="space-y-2">
          <div>
            <Label className="text-xs">Screen Title</Label>
            <Input
              value={currentScreen.title}
              onChange={(e) => updateScreen(currentScreen.id, { title: e.target.value })}
              className="text-xs"
            />
          </div>

          <div className="flex items-center gap-2">
            <label className="flex items-center gap-1 text-xs">
              <input
                type="checkbox"
                checked={currentScreen.terminal || false}
                onChange={(e) => updateScreen(currentScreen.id, { terminal: e.target.checked })}
                className="w-3 h-3"
              />
              Terminal Screen
            </label>
          </div>
        </div>

        <div>
          <div className="flex items-center justify-between mb-2">
            <Label className="text-xs">Components</Label>
            <Select onValueChange={(value) => addComponentToScreen(currentScreen.id, value)}>
              <SelectTrigger className="w-auto text-xs">
                <SelectValue placeholder="Add Component" />
              </SelectTrigger>
              <SelectContent>
                {Object.entries(
                  FLOW_COMPONENTS.reduce((acc, comp) => {
                    if (!acc[comp.category]) acc[comp.category] = [];
                    acc[comp.category].push(comp);
                    return acc;
                  }, {} as Record<string, typeof FLOW_COMPONENTS>)
                ).map(([category, components]) => (
                  <div key={category}>
                    <div className="px-2 py-1 text-xs font-medium text-muted-foreground">
                      {category.charAt(0).toUpperCase() + category.slice(1)}
                    </div>
                    {components.map(comp => (
                      <SelectItem key={comp.type} value={comp.type} className="text-xs">
                        {comp.icon} {comp.name}
                      </SelectItem>
                    ))}
                  </div>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1 max-h-32 overflow-y-auto">
            {currentScreen.layout.children.map((component, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-secondary/20 rounded text-xs">
                <div className="flex items-center gap-2 flex-1">
                  <span>{FLOW_COMPONENTS.find(c => c.type === component.type)?.icon}</span>
                  <div className="flex-1">
                    <div className="font-medium">{FLOW_COMPONENTS.find(c => c.type === component.type)?.name || component.type}</div>
                    <div className="text-muted-foreground text-[10px]">
                      {component.label || component.text || component.name || 'Component'}
                    </div>
                  </div>
                </div>
                <div className="flex gap-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setSelectedComponent(component.type + '_' + index)}
                    className="h-6 w-6 p-0"
                  >
                    <Settings className="h-3 w-3" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      const newChildren = currentScreen.layout.children.filter((_, i) => i !== index);
                      updateScreen(currentScreen.id, {
                        layout: { ...currentScreen.layout, children: newChildren }
                      });
                    }}
                    className="h-6 w-6 p-0"
                  >
                    <X className="h-3 w-3" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  const renderComponentEditor = () => {
    if (!selectedComponent || !selectedScreen) return null;

    const currentScreen = screens.find(s => s.id === selectedScreen);
    if (!currentScreen) return null;

    const [componentType, indexStr] = selectedComponent.split('_');
    const componentIndex = parseInt(indexStr);
    const component = currentScreen.layout.children[componentIndex];
    
    if (!component) return null;

    const updateComponent = (updates: Partial<FlowComponent>) => {
      const newChildren = [...currentScreen.layout.children];
      newChildren[componentIndex] = { ...component, ...updates };
      updateScreen(currentScreen.id, {
        layout: { ...currentScreen.layout, children: newChildren }
      });
    };

    return (
      <div className="space-y-3 border-t pt-3 mt-3">
        <div className="flex items-center justify-between">
          <h4 className="text-sm font-medium">
            Edit {FLOW_COMPONENTS.find(c => c.type === component.type)?.name || component.type}
          </h4>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setSelectedComponent('')}
            className="h-6 w-6 p-0"
          >
            <X className="h-3 w-3" />
          </Button>
        </div>

        <div className="space-y-2">
          {/* Common properties */}
          {(component.text !== undefined || component.type.includes('Text')) && (
            <div>
              <Label className="text-xs">Text</Label>
              <Input
                value={component.text || ''}
                onChange={(e) => updateComponent({ text: e.target.value })}
                className="text-xs"
                placeholder="Enter text..."
              />
            </div>
          )}

          {(component.label !== undefined || component.type !== 'TextHeading') && (
            <div>
              <Label className="text-xs">Label</Label>
              <Input
                value={component.label || ''}
                onChange={(e) => updateComponent({ label: e.target.value })}
                className="text-xs"
                placeholder="Enter label..."
              />
            </div>
          )}

          {(component.name !== undefined || ['TextInput', 'TextArea', 'DatePicker', 'Dropdown', 'CheckboxGroup', 'RadioButtonsGroup'].includes(component.type)) && (
            <div>
              <Label className="text-xs">Field Name</Label>
              <Input
                value={component.name || ''}
                onChange={(e) => updateComponent({ name: e.target.value })}
                className="text-xs"
                placeholder="field_name"
              />
            </div>
          )}

          {(component.placeholder !== undefined || ['TextInput', 'TextArea'].includes(component.type)) && (
            <div>
              <Label className="text-xs">Placeholder</Label>
              <Input
                value={component.placeholder || ''}
                onChange={(e) => updateComponent({ placeholder: e.target.value })}
                className="text-xs"
                placeholder="Enter placeholder..."
              />
            </div>
          )}

          {(component.required !== undefined || ['TextInput', 'TextArea', 'DatePicker', 'Dropdown', 'CheckboxGroup', 'RadioButtonsGroup'].includes(component.type)) && (
            <div className="flex items-center gap-2">
              <label className="flex items-center gap-1 text-xs">
                <input
                  type="checkbox"
                  checked={component.required || false}
                  onChange={(e) => updateComponent({ required: e.target.checked })}
                  className="w-3 h-3"
                />
                Required Field
              </label>
            </div>
          )}

          {component.type === 'TextInput' && (
            <div>
              <Label className="text-xs">Input Type</Label>
              <Select 
                value={component.input_type || 'text'} 
                onValueChange={(value) => updateComponent({ input_type: value })}
              >
                <SelectTrigger className="h-8 text-xs">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="text">Text</SelectItem>
                  <SelectItem value="email">Email</SelectItem>
                  <SelectItem value="phone">Phone</SelectItem>
                  <SelectItem value="number">Number</SelectItem>
                  <SelectItem value="password">Password</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          {(component.type === 'Footer' && component['on-click-action']) && (
            <div>
              <Label className="text-xs">Action Type</Label>
              <Select 
                value={component['on-click-action']?.name || 'complete'} 
                onValueChange={(value) => updateComponent({ 
                  'on-click-action': { 
                    name: value, 
                    payload: value === 'complete' ? {} : { next: { name: '' } }
                  } 
                })}
              >
                <SelectTrigger className="h-8 text-xs">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {FLOW_ACTIONS.map((action) => (
                    <SelectItem key={action.type} value={action.type}>
                      {action.icon} {action.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="node-whatsapp-flows p-3 rounded-lg bg-white border border-green-200 shadow-sm max-w-[320px] group">
      <div className="absolute -top-8 -right-2 bg-background border rounded-md shadow-sm flex z-10 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7"
                onClick={() => onDuplicateNode(id)}
              >
                <Copy className="h-3.5 w-3.5" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="top">
              <p className="text-xs">Duplicate node</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>

        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7 text-destructive hover:text-destructive"
                onClick={() => onDeleteNode(id)}
              >
                <Trash2 className="h-3.5 w-3.5" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="top">
              <p className="text-xs">Delete node</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </div>

      <div className="font-medium flex items-center gap-2 mb-2">
        <MessageSquare className="h-4 w-4 text-green-600" />
        <span>WhatsApp Flows</span>
        <span className="px-1.5 py-0.5 text-[9px] font-medium bg-green-100 text-green-700 rounded border border-green-200">
          Official API
        </span>
        <button
          className="ml-auto text-xs text-muted-foreground hover:text-foreground flex items-center gap-1"
          onClick={() => setIsEditing(!isEditing)}
        >
          {isEditing ? (
            <>
              <EyeOff className="h-3 w-3" />
              Hide
            </>
          ) : (
            <>
              <Eye className="h-3 w-3" />
              Edit
            </>
          )}
        </button>
      </div>

      <div className="text-sm p-2 bg-secondary/40 rounded border border-border">
        <div className="flex items-center gap-1 mb-1">
          <MessageSquare className="h-3.5 w-3.5 text-muted-foreground" />
          <span className="font-medium text-green-600">FLOW</span>
          <span className="text-muted-foreground">•</span>
          <span className="text-xs text-muted-foreground truncate">
            {flowName || 'Untitled Flow'}
          </span>
        </div>
        
        <div className="text-xs text-muted-foreground">
          {screens.length} screen{screens.length !== 1 ? 's' : ''} • v{flowVersion}
        </div>
      </div>

      {isEditing && (
        <div className="mt-3 space-y-3 text-xs">
          {/* Flow Configuration Tabs */}
          <div className="flex border-b">
            {[
              { id: 'design', label: 'Design', icon: Settings },
              { id: 'settings', label: 'Settings', icon: Settings },
              { id: 'json', label: 'JSON', icon: Settings },
              { id: 'preview', label: 'Preview', icon: Eye }
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={cn(
                  "flex items-center gap-1 px-2 py-1 text-xs border-b-2 transition-colors",
                  activeTab === tab.id
                    ? "border-green-500 text-green-600"
                    : "border-transparent text-muted-foreground hover:text-foreground"
                )}
              >
                <tab.icon className="h-3 w-3" />
                {tab.label}
              </button>
            ))}
          </div>

          {/* Basic Configuration */}
          <div className="space-y-2">
            <div>
              <Label className="text-xs">Flow Name</Label>
              <Input
                value={flowName}
                onChange={(e) => setFlowName(e.target.value)}
                placeholder="Enter flow name"
                className="text-xs"
              />
            </div>

            {/* WhatsApp Connection Status */}
            <div>
              <Label className="text-xs">WhatsApp Business Connection</Label>
              <div className={cn(
                "p-2 rounded border text-xs",
                whatsappConnection.isConfigured
                  ? "bg-green-50 border-green-200 text-green-700"
                  : "bg-red-50 border-red-200 text-red-700"
              )}>
                <div className="flex items-center gap-2">
                  {whatsappConnection.isConfigured ? (
                    <>
                      <CheckCircle className="h-3 w-3" />
                      <span>Connected</span>
                    </>
                  ) : (
                    <>
                      <XCircle className="h-3 w-3" />
                      <span>Not Connected</span>
                    </>
                  )}
                </div>
                {whatsappConnection.isConfigured && (
                  <div className="text-[10px] text-muted-foreground mt-1">
                    Phone ID: {whatsappConnection.businessPhoneNumberId ? 
                      `...${whatsappConnection.businessPhoneNumberId.slice(-8)}` : 
                      'Not available'
                    }
                  </div>
                )}
                {!whatsappConnection.isConfigured && (
                  <div className="text-[10px] mt-1">
                    Please configure your WhatsApp Business channel in Settings
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Tab Content */}
          {activeTab === 'settings' && (
            <div className="space-y-3">
              {/* Advanced Flow Settings */}
              <div className="space-y-2">
                <Label className="text-xs">Advanced Settings</Label>
                
                <div>
                  <Label className="text-xs text-muted-foreground">Data Channel URI</Label>
                  <Input
                    value={dataChannelUri}
                    onChange={(e) => setDataChannelUri(e.target.value)}
                    placeholder="https://your-endpoint.com/webhook"
                    className="text-xs"
                  />
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <Label className="text-xs text-muted-foreground">Flow Categories</Label>
                    <Select defaultValue="OTHER">
                      <SelectTrigger className="text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="SIGN_UP">Sign Up</SelectItem>
                        <SelectItem value="SIGN_IN">Sign In</SelectItem>
                        <SelectItem value="APPOINTMENT_BOOKING">Appointment Booking</SelectItem>
                        <SelectItem value="LEAD_GENERATION">Lead Generation</SelectItem>
                        <SelectItem value="CONTACT_US">Contact Us</SelectItem>
                        <SelectItem value="CUSTOMER_SUPPORT">Customer Support</SelectItem>
                        <SelectItem value="OTHER">Other</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  
                  <div>
                    <Label className="text-xs text-muted-foreground">Mode</Label>
                    <Select defaultValue="PUBLISHED">
                      <SelectTrigger className="text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="DRAFT">Draft</SelectItem>
                        <SelectItem value="PUBLISHED">Published</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">Flow Message Settings</Label>
                  
                  <div>
                    <Label className="text-xs">Header Text (Optional)</Label>
                    <Input
                      placeholder="Header message"
                      className="text-xs"
                    />
                  </div>
                  
                  <div>
                    <Label className="text-xs">Body Text</Label>
                    <Textarea
                      placeholder="Please complete this form to continue..."
                      className="text-xs h-16 resize-none"
                    />
                  </div>
                  
                  <div>
                    <Label className="text-xs">Footer Text (Optional)</Label>
                    <Input
                      placeholder="Footer message"
                      className="text-xs"
                    />
                  </div>
                  
                  <div>
                    <Label className="text-xs">Button Text</Label>
                    <Input
                      placeholder="Open Form"
                      className="text-xs"
                    />
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <label className="flex items-center gap-1 text-xs">
                    <input
                      type="checkbox"
                      className="w-3 h-3"
                    />
                    Send flow immediately after creation
                  </label>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'design' && (
            <div className="space-y-3">
              {/* Template Selection */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label className="text-xs">Quick Start Templates</Label>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setScreens([])}
                    className="text-xs h-6"
                  >
                    Clear All
                  </Button>
                </div>
                
                <div className="grid grid-cols-1 gap-2 max-h-32 overflow-y-auto">
                  {FLOW_TEMPLATES.map(template => (
                    <button
                      key={template.id}
                      onClick={() => {
                        setScreens(template.screens as FlowScreen[]);
                        setFlowName(template.name);
                        if (template.screens.length > 0) {
                          setSelectedScreen(template.screens[0].id);
                        }
                      }}
                      className="p-2 text-left bg-secondary/20 hover:bg-secondary/40 rounded text-xs transition-colors"
                    >
                      <div className="font-medium">{template.name}</div>
                      <div className="text-muted-foreground text-[10px]">{template.description}</div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Flow Settings */}
              <div className="space-y-2">
                <Label className="text-xs">Flow Settings</Label>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <Label className="text-xs text-muted-foreground">Version</Label>
                    <Select value={flowVersion} onValueChange={setFlowVersion}>
                      <SelectTrigger className="text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="7.2">7.2 (Latest)</SelectItem>
                        <SelectItem value="7.1">7.1</SelectItem>
                        <SelectItem value="7.0">7.0</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  
                  <div>
                    <Label className="text-xs text-muted-foreground">Data API</Label>
                    <Select value={dataApiVersion} onValueChange={setDataApiVersion}>
                      <SelectTrigger className="text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="3.0">3.0</SelectItem>
                        <SelectItem value="2.0">2.0</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              {/* Screens Management */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label className="text-xs">Screens</Label>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={addScreen}
                    className="text-xs h-6"
                  >
                    <Plus className="h-3 w-3 mr-1" />
                    Add Screen
                  </Button>
                </div>

                <div className="space-y-1 max-h-20 overflow-y-auto">
                  {screens.map(screen => (
                    <button
                      key={screen.id}
                      onClick={() => setSelectedScreen(screen.id)}
                      className={cn(
                        "w-full text-left p-2 rounded text-xs transition-colors",
                        selectedScreen === screen.id
                          ? "bg-green-50 border border-green-200"
                          : "bg-secondary/20 hover:bg-secondary/40"
                      )}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-medium">{screen.title}</span>
                        <span className="text-muted-foreground">
                          {screen.layout.children.length} components
                        </span>
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Screen Designer */}
              {selectedScreen && renderScreenDesigner()}
              
              {/* Component Editor */}
              {selectedComponent && renderComponentEditor()}
            </div>
          )}

          {activeTab === 'json' && (
            <div className="space-y-2">
              <Label className="text-xs">Flow JSON</Label>
              <Textarea
                value={JSON.stringify(generateFlowJSON(), null, 2)}
                readOnly
                className="text-[10px] font-mono h-40 resize-none"
              />
            </div>
          )}

          {activeTab === 'preview' && (
            <div className="space-y-2">
              <Label className="text-xs">Flow Preview</Label>
              <div className="bg-gray-50 p-3 rounded text-center text-xs text-muted-foreground">
                Interactive preview would be displayed here
              </div>
            </div>
          )}

          {/* Test Connection */}
          <div className="pt-2 border-t">
            <div className="flex gap-2">
              <Button
                onClick={testFlow}
                disabled={isTesting}
                size="sm"
                className="flex-1 text-xs"
              >
                {isTesting ? (
                  <>
                    <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                    Testing...
                  </>
                ) : (
                  <>
                    <Play className="h-3 w-3 mr-1" />
                    Test Flow
                  </>
                )}
              </Button>
              
              <Button
                variant="outline"
                size="sm"
                onClick={() => setIsExpanded(!isExpanded)}
                className="text-xs"
              >
                {isExpanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
              </Button>
            </div>
          </div>

          {/* Test Results */}
          {showTestResult && testResult && (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label className="text-xs">Test Result</Label>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowTestResult(false)}
                >
                  <X className="h-3 w-3" />
                </Button>
              </div>

              {testResult.error ? (
                <div className="text-xs text-red-600 bg-red-50 p-2 rounded">
                  {testResult.error}
                </div>
              ) : (
                <div className="space-y-2">
                  <div className="text-xs text-green-600 bg-green-50 p-2 rounded">
                    <div className="flex items-center gap-1">
                      <CheckCircle className="h-3 w-3" />
                      Flow created successfully
                    </div>
                  </div>

                  {testResult.data && (
                    <div>
                      <div className="text-xs font-medium text-muted-foreground mb-1">
                        Response Data:
                      </div>
                      <div className="text-[10px] bg-gray-50 p-2 rounded font-mono max-h-32 overflow-y-auto">
                        {JSON.stringify(testResult.data, null, 2)}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      <Handle
        type="target"
        position={Position.Left}
        style={standardHandleStyle}
        isConnectable={isConnectable}
      />

      <Handle
        type="source"
        position={Position.Right}
        style={standardHandleStyle}
        isConnectable={isConnectable}
      />
    </div>
  );
}
