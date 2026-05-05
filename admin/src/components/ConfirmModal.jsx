import { useState } from 'react';
import { Modal, Text, Group, Button, Stack } from '@mantine/core';
import { NAVY } from '../theme';

export default function ConfirmModal({ opened, onClose, onConfirm }) {
  const [step, setStep] = useState(1);

  function handleClose() {
    setStep(1);
    onClose();
  }

  function handleConfirm() {
    setStep(1);
    onConfirm();
  }

  return (
    <Modal
      opened={opened}
      onClose={handleClose}
      title={
        <Text fw={700} size="lg" c="navy.6">
          {step === 1 ? 'Kustuta andmed' : 'Oled sa täiesti kindel?'}
        </Text>
      }
      centered
      radius="md"
    >
      <Stack>
        <Text size="sm" c="dimmed" lh={1.6}>
          {step === 1
            ? 'Kõik statistikaandmed kustutatakse jäädavalt. Seda ei saa tagasi võtta.'
            : 'Tõesti kõik? Päriselt? Seda ei saa tagasi võtta.'}
        </Text>
        <Group justify="flex-end" mt="xs" gap={8}>
          <Button
            variant="outline"
            radius="xl"
            onClick={handleClose}
            styles={{ root: { borderColor: NAVY, color: NAVY } }}
          >
            Tühista
          </Button>
          {step === 1 ? (
            <Button color="red" radius="xl" onClick={() => setStep(2)}>
              Kustuta
            </Button>
          ) : (
            <Button color="red" radius="xl" onClick={handleConfirm}>
              Jah, kustuta kõik
            </Button>
          )}
        </Group>
      </Stack>
    </Modal>
  );
}
