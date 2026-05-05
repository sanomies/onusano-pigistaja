import { useState, useEffect, useCallback } from 'react';
import {
  Box, Group, Image, Button, Burger, Menu,
} from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { notifications } from '@mantine/notifications';
import { db, ADMIN_EMAIL } from '../supabase';
import { BG, NAVY } from '../theme';
import logoSrc from '../../../assets/admin-panel-logo.svg';
import StatCards from './StatCards';
import CotmCard from './CotmCard';
import ChartsRow from './ChartsRow';
import UserTable from './UserTable';
import ConfirmModal from './ConfirmModal';

export default function Dashboard({ user, onLogout }) {
  const [runs, setRuns]           = useState([]);
  const [authUsers, setAuthUsers] = useState([]);
  const [confirmOpen, { open: openConfirm, close: closeConfirm }] = useDisclosure(false);
  const [burgerOpen, { toggle: toggleBurger, close: closeBurger }] = useDisclosure(false);
  const isAdmin = user?.email === ADMIN_EMAIL;

  const fetchData = useCallback(async () => {
    const [{ data: runsData }, { data: usersData }] = await Promise.all([
      db.from('compression_runs').select('*').order('created_at', { ascending: true }),
      db.rpc('list_auth_users'),
    ]);
    if (runsData)  setRuns(runsData);
    if (usersData) setAuthUsers(usersData);
  }, []);

  useEffect(() => {
    fetchData();
    const channel = db
      .channel('compression_runs_live')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'compression_runs' }, fetchData)
      .subscribe();
    return () => { db.removeChannel(channel); };
  }, [fetchData]);

  async function handleLogout() {
    await db.auth.signOut();
    onLogout();
  }

  async function handleDeleteAll() {
    const { error } = await db
      .from('compression_runs')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
    closeConfirm();
    if (error) {
      notifications.show({ color: 'red', title: 'Viga', message: error.message });
      return;
    }
    fetchData();
  }

  const animDelay = (delay) => ({
    animation: `fadeUp 0.5s cubic-bezier(.22,1,.36,1) ${delay}s both`,
  });

  return (
    <Box style={{ minHeight: '100vh', background: BG }}>

      {/* ── Header ── */}
      <Box style={{ borderBottom: `2px solid rgba(18,28,87,.08)` }} {...animDelay(0)}>
        <Box maw={1100} mx="auto" px="lg">
          <Group justify="space-between" py="lg">

            <Image
              src={logoSrc}
              h={50}
              w="auto"
              fit="contain"
              alt="Admin Panel"
            />

            {/* Desktop buttons */}
            <Group gap={8} visibleFrom="sm">
              {isAdmin && (
                <Button variant="outline" color="red" size="sm" onClick={openConfirm}>
                  Kustuta andmed
                </Button>
              )}
              <Button
                variant="outline"
                size="sm"
                onClick={handleLogout}
                styles={{
                  root: {
                    borderColor: NAVY,
                    color: NAVY,
                    '&:hover': { background: NAVY, color: '#fff' },
                  },
                }}
              >
                Logi välja
              </Button>
            </Group>

            {/* Mobile burger */}
            <Menu
              opened={burgerOpen}
              onClose={closeBurger}
              shadow="md"
              width={200}
              position="bottom-end"
              radius="md"
            >
              <Menu.Target>
                <Burger
                  hiddenFrom="sm"
                  opened={burgerOpen}
                  onClick={toggleBurger}
                  size="sm"
                />
              </Menu.Target>
              <Menu.Dropdown>
                {isAdmin && (
                  <Menu.Item
                    color="red"
                    onClick={() => { closeBurger(); openConfirm(); }}
                  >
                    Kustuta andmed
                  </Menu.Item>
                )}
                <Menu.Item onClick={handleLogout}>Logi välja</Menu.Item>
              </Menu.Dropdown>
            </Menu>

          </Group>
        </Box>
      </Box>

      {/* ── Main content ── */}
      <Box maw={1100} mx="auto" px="lg" pb={64}>
        <Box style={animDelay(0.08)}><StatCards runs={runs} userCount={authUsers.length} /></Box>
        <Box style={animDelay(0.16)}><CotmCard runs={runs} /></Box>
        <Box style={animDelay(0.24)}><ChartsRow runs={runs} /></Box>
        <Box style={animDelay(0.32)}><UserTable runs={runs} authUsers={authUsers} /></Box>
      </Box>

      <ConfirmModal opened={confirmOpen} onClose={closeConfirm} onConfirm={handleDeleteAll} />
    </Box>
  );
}
