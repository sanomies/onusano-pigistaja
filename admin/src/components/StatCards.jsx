import { SimpleGrid, Paper, Text, Stack } from '@mantine/core';

function fmtBytes(bytes) {
  if (bytes >= 1e9) return { value: (bytes / 1e9).toFixed(1), unit: 'gb' };
  if (bytes >= 1e6) return { value: (bytes / 1e6).toFixed(1), unit: 'mb' };
  if (bytes >= 1e3) return { value: (bytes / 1e3).toFixed(0), unit: 'kb' };
  return { value: String(bytes), unit: 'b' };
}

function startOfWeek() {
  const d = new Date();
  d.setDate(d.getDate() - d.getDay());
  d.setHours(0, 0, 0, 0);
  return d;
}

function StatCard({ value, unit, label }) {
  return (
    <Paper shadow="sm" p="lg" radius="md" h="100%">
      <Stack gap={6} justify="space-between" h="100%">
        <Text
          fw={800}
          lh={1}
          c="navy.6"
          style={{ fontSize: 'clamp(32px, 4vw, 50px)' }}
        >
          {value}
          {unit && (
            <Text component="span" fw={800} style={{ fontSize: '0.64em' }} c="navy.6">
              {' '}{unit}
            </Text>
          )}
        </Text>
        <Text
          size="xs"
          fw={500}
          tt="uppercase"
          c="navy.6"
          style={{ opacity: 0.6, letterSpacing: '0.04em' }}
        >
          {label}
        </Text>
      </Stack>
    </Paper>
  );
}

export default function StatCards({ runs, userCount }) {
  const weekStart    = startOfWeek();
  const runsThisWeek = runs.filter(r => new Date(r.created_at) >= weekStart).length;

  const totalIn  = runs.reduce((s, r) => s + (r.total_input_bytes  || 0), 0);
  const totalOut = runs.reduce((s, r) => s + (r.total_output_bytes || 0), 0);
  const bytes    = fmtBytes(totalIn - totalOut);
  const ratio    = totalIn > 0 ? ((1 - totalOut / totalIn) * 100).toFixed(0) : '0';

  return (
    <SimpleGrid cols={{ base: 2, md: 4 }} spacing="md" mt="xl" mb="md">
      <StatCard value={userCount ?? '—'} label="Registreeritud kasutajat" />
      <StatCard value={runsThisWeek}     label="Pigistust sel nädalal" />
      <StatCard value={bytes.value} unit={bytes.unit} label="Kokku ruumi kokku hoitud" />
      <StatCard value={ratio} unit="%" label="Keskmine tihendussuhe" />
    </SimpleGrid>
  );
}
