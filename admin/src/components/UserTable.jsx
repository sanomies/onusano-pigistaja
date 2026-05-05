import { Paper, Table, Text, Stack } from '@mantine/core';

export default function UserTable({ runs, authUsers }) {
  const users = {};
  (authUsers || []).forEach(u => {
    users[u.email] = { lastActive: u.created_at, runs: 0, files: 0 };
  });

  runs.forEach(r => {
    if (!users[r.email]) users[r.email] = { lastActive: r.created_at, runs: 0, files: 0 };
    const u = users[r.email];
    if (r.created_at > u.lastActive) u.lastActive = r.created_at;
    u.runs  += 1;
    u.files += (r.file_count || 0);
  });

  const rows = Object.entries(users).sort((a, b) => b[1].files - a[1].files);

  const thStyle = {
    textTransform: 'uppercase',
    fontSize: 11,
    letterSpacing: '0.05em',
    opacity: 0.6,
    fontWeight: 700,
    color: 'inherit',
  };

  return (
    <Stack gap="xs">
      <Text fw={700} size="xl" c="navy.6">Kasutajad</Text>
      <Paper shadow="sm" radius="md" style={{ overflow: 'hidden' }}>
        <Table highlightOnHover fz="sm">
          <Table.Thead style={{ background: 'rgba(18,28,87,.04)' }}>
            <Table.Tr>
              <Table.Th style={thStyle}>E-post</Table.Th>
              <Table.Th style={thStyle}>Viimati aktiivne</Table.Th>
              <Table.Th style={thStyle}>Pigistusi kokku</Table.Th>
              <Table.Th style={thStyle}>Faile kokku</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {rows.map(([email, u]) => (
              <Table.Tr key={email}>
                <Table.Td>{email}</Table.Td>
                <Table.Td>{new Date(u.lastActive).toLocaleDateString('et-EE', { day: '2-digit', month: '2-digit', year: 'numeric' })}</Table.Td>
                <Table.Td>{u.runs}</Table.Td>
                <Table.Td>{u.files}</Table.Td>
              </Table.Tr>
            ))}
          </Table.Tbody>
        </Table>
      </Paper>
    </Stack>
  );
}
