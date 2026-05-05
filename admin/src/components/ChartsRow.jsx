import { Grid, Paper, Text, Stack, Group, Progress } from '@mantine/core';
import { useElementSize } from '@mantine/hooks';
import { AreaChart } from '@mantine/charts';

function ymd(str) { return str.slice(0, 10); }

export default function ChartsRow({ runs }) {
  const { ref: sizesRef, height: sizesHeight } = useElementSize();
  // Daily active users — last 30 days
  const dauData = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = ymd(d.toISOString());
    dauData.push({
      date: key.slice(5),
      users: new Set(runs.filter(r => ymd(r.created_at) === key).map(r => r.user_id)).size,
    });
  }

  // Top banner sizes
  const counts = {};
  runs.forEach(r => {
    (r.banner_sizes || []).forEach(s => { counts[s] = (counts[s] || 0) + 1; });
  });
  const sizesData = Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([size, count]) => ({ size, count }));

  return (
    <Grid mb="md" gutter="md">

      <Grid.Col span={{ base: 12, md: 8 }}>
        <Stack gap="xs">
          <Text fw={700} size="xl" c="navy.6">Aktiivsed kasutajad (30 päeva)</Text>
          <Paper shadow="sm" p="lg" radius="md">
            {dauData.every(d => d.users === 0) ? (
              <Text size="sm" c="dimmed">Veel pole andmeid</Text>
            ) : (
              <AreaChart
                h={sizesHeight || 220}
                data={dauData}
                dataKey="date"
                series={[{ name: 'users', color: 'navy.6', label: 'Kasutajad' }]}
                curveType="monotone"
                withDots={false}
                withLegend={false}
                withTooltip
                tooltipAnimationDuration={200}
                xAxisProps={{ tickLine: false, axisLine: false, interval: 4 }}
                yAxisProps={{ tickLine: false, axisLine: false }}
                gridAxis="y"
              />
            )}
          </Paper>
        </Stack>
      </Grid.Col>

      <Grid.Col span={{ base: 12, md: 4 }}>
        <Stack gap="xs">
          <Text fw={700} size="xl" c="navy.6">Top bänneri mõõdud</Text>
          <Paper shadow="sm" p="lg" radius="md">
            <Stack gap="sm" ref={sizesRef}>
              {sizesData.length === 0 && (
                <Text size="sm" c="dimmed">Veel pole andmeid</Text>
              )}
              {sizesData.map(({ size, count }) => (
                <Stack key={size} gap={4}>
                  <Group justify="space-between">
                    <Text size="sm" fw={500} c="navy.6">{size}</Text>
                    <Text size="sm" c="dimmed">{count}</Text>
                  </Group>
                  <Progress
                    value={(count / sizesData[0].count) * 100}
                    color="orange.5"
                    radius="xl"
                    size="sm"
                  />
                </Stack>
              ))}
            </Stack>
          </Paper>
        </Stack>
      </Grid.Col>

    </Grid>
  );
}
