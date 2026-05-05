import { useState } from 'react';
import {
  Box, Paper, Title, TextInput, PasswordInput,
  Button, Text, Stack,
} from '@mantine/core';
import { db } from '../supabase';
import { BG } from '../theme';

export default function LoginGate({ onLogin }) {
  const [email, setEmail]       = useState('');
  const [password, setPassword] = useState('');
  const [error, setError]       = useState('');
  const [loading, setLoading]   = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    const { error: err, data } = await db.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (err) { setError(err.message); return; }
    onLogin(data.user);
  }

  return (
    <Box
      style={{
        minHeight: '100vh',
        background: BG,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <Paper shadow="md" p={40} w={320} radius="lg">
        <Title order={2} mb="lg" c="navy.6" fw={700}>
          Admin
        </Title>
        <form onSubmit={handleSubmit}>
          <Stack gap="sm">
            <TextInput
              type="email"
              placeholder="E-post"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
            <PasswordInput
              placeholder="Parool"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              autoComplete="current-password"
            />
            {error && <Text size="sm" c="red">{error}</Text>}
            <Button type="submit" color="orange" loading={loading} mt={4} fw={700}>
              Logi sisse
            </Button>
          </Stack>
        </form>
      </Paper>
    </Box>
  );
}
