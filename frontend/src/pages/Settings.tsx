import AppLayout from '@/components/layout/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import AdminSettings from './settings/AdminSettings';
import OwnerSettings from './settings/OwnerSettings';

const settingsTitle: Record<string, { title: string; subtitle: string }> = {
  super_admin: { title: 'Settings',  subtitle: 'Manage registered shops and system configuration' },
  owner:       { title: 'My Shop',   subtitle: 'Manage your shop details, branches and staff' },
};

const Settings = () => {
  const { user } = useAuth();
  const meta = settingsTitle[user?.role ?? ''] ?? settingsTitle.owner;

  return (
    <AppLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">{meta.title}</h1>
          <p className="text-sm text-muted-foreground">{meta.subtitle}</p>
        </div>

        {user?.role === 'super_admin' && <AdminSettings />}
        {user?.role === 'owner' && <OwnerSettings />}
      </div>
    </AppLayout>
  );
};

export default Settings;

