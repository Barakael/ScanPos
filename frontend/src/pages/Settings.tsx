import { useState, useEffect } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { settingsApi, SettingsPayload } from '@/services/api';
import { Save, Store, Phone, Mail, MapPin, Percent, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';

const Settings = () => {
  const queryClient = useQueryClient();

  const { data: serverSettings, isLoading } = useQuery<Record<string, string>>({
    queryKey: ['settings'],
    queryFn: () => settingsApi.getAll(),
  });

  const [form, setForm] = useState<SettingsPayload>({
    store_name: '',
    store_address: '',
    store_phone: '',
    store_email: '',
    tax_rate: '',
    currency: '',
  });

  // Sync form from server when data loads
  useEffect(() => {
    if (serverSettings) {
      setForm({
        store_name:    serverSettings.store_name    ?? '',
        store_address: serverSettings.store_address ?? '',
        store_phone:   serverSettings.store_phone   ?? '',
        store_email:   serverSettings.store_email   ?? '',
        tax_rate:      serverSettings.tax_rate       ?? '18',
        currency:      serverSettings.currency       ?? 'TZS',
      });
    }
  }, [serverSettings]);

  const saveMutation = useMutation({
    mutationFn: (data: SettingsPayload) => settingsApi.update(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] });
      toast.success('Settings saved successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });

  const handleSave = () => {
    const taxRate = Number(form.tax_rate);
    if (isNaN(taxRate) || taxRate < 0 || taxRate > 100) {
      toast.error('Tax rate must be between 0 and 100');
      return;
    }
    saveMutation.mutate(form);
  };

  const set = (key: keyof SettingsPayload) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm(prev => ({ ...prev, [key]: e.target.value }));

  return (
    <AppLayout>
      <div className="space-y-6 max-w-2xl">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-foreground">Settings</h1>
          <p className="text-sm text-muted-foreground">Manage your store configuration</p>
        </div>

        {isLoading ? (
          <div className="flex items-center gap-2 text-muted-foreground text-sm">
            <RefreshCw className="w-4 h-4 animate-spin" /> Loading settings…
          </div>
        ) : (
          <div className="space-y-6">
            {/* Store Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Store className="w-4 h-4" /> Store Information
                </CardTitle>
                <CardDescription>Basic details displayed on receipts and reports</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="store_name">Store Name</Label>
                  <Input
                    id="store_name"
                    value={form.store_name as string}
                    onChange={set('store_name')}
                    placeholder="e.g. MyPOS Store"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="store_address" className="flex items-center gap-1">
                    <MapPin className="w-3.5 h-3.5" /> Address
                  </Label>
                  <Input
                    id="store_address"
                    value={form.store_address as string}
                    onChange={set('store_address')}
                    placeholder="e.g. 123 Main St, Dar es Salaam"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="store_phone" className="flex items-center gap-1">
                      <Phone className="w-3.5 h-3.5" /> Phone
                    </Label>
                    <Input
                      id="store_phone"
                      value={form.store_phone as string}
                      onChange={set('store_phone')}
                      placeholder="+255 712 345 678"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="store_email" className="flex items-center gap-1">
                      <Mail className="w-3.5 h-3.5" /> Email
                    </Label>
                    <Input
                      id="store_email"
                      type="email"
                      value={form.store_email as string}
                      onChange={set('store_email')}
                      placeholder="store@example.com"
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Sales & Tax */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Percent className="w-4 h-4" /> Sales &amp; Tax
                </CardTitle>
                <CardDescription>Tax and currency settings applied to all sales</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="tax_rate">Tax Rate (%)</Label>
                    <div className="relative">
                      <Input
                        id="tax_rate"
                        type="number"
                        min={0}
                        max={100}
                        step={0.01}
                        value={form.tax_rate as string}
                        onChange={set('tax_rate')}
                        className="pr-8"
                      />
                      <span className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">%</span>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="currency">Currency Code</Label>
                    <Input
                      id="currency"
                      value={form.currency as string}
                      onChange={set('currency')}
                      placeholder="TZS"
                      maxLength={10}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Save */}
            <div className="flex justify-end">
              <Button onClick={handleSave} disabled={saveMutation.isPending} className="gap-2">
                <Save className="w-4 h-4" />
                {saveMutation.isPending ? 'Saving…' : 'Save Changes'}
              </Button>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
};

export default Settings;
