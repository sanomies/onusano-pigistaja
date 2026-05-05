import { useEffect, useRef } from 'react';
import { Box, Text, Badge } from '@mantine/core';
import { NAVY, ORANGE } from '../theme';
import trophySrc from '../../../assets/trophy.png';

const CONFETTI = [
  { x: '6%',  y: '20%', d: '0s',   s: 7,  odd: true  },
  { x: '18%', y: '70%', d: '-6s',  s: 6,  odd: false },
  { x: '32%', y: '40%', d: '-11s', s: 8,  odd: true  },
  { x: '50%', y: '80%', d: '-4s',  s: 5,  odd: false },
  { x: '65%', y: '25%', d: '-15s', s: 7,  odd: true  },
  { x: '78%', y: '60%', d: '-8s',  s: 6,  odd: false },
  { x: '88%', y: '35%', d: '-2s',  s: 5,  odd: true  },
  { x: '42%', y: '55%', d: '-18s', s: 7,  odd: false },
  { x: '12%', y: '45%', d: '-9s',  s: 6,  odd: true  },
  { x: '72%', y: '75%', d: '-13s', s: 8,  odd: false },
  { x: '25%', y: '15%', d: '-7s',  s: 5,  odd: true  },
  { x: '58%', y: '50%', d: '-16s', s: 6,  odd: false },
  { x: '82%', y: '20%', d: '-3s',  s: 7,  odd: true  },
];

const COLORS = [
  'rgba(247,117,42,.56)', 'rgba(255,255,255,.4)', 'rgba(247,117,42,.44)',
  'rgba(255,220,100,.48)', 'rgba(255,255,255,.36)', 'rgba(247,117,42,.48)',
  'rgba(255,220,100,.4)', 'rgba(255,255,255,.4)', 'rgba(247,160,60,.52)',
  'rgba(255,255,255,.32)', 'rgba(255,220,100,.44)', 'rgba(247,117,42,.4)',
  'rgba(255,255,255,.36)',
];

export default function CotmCard({ runs }) {
  const feHueRef = useRef(null);
  const rafRef   = useRef(null);

  useEffect(() => {
    let start = null;
    function tick(ts) {
      if (!start) start = ts;
      if (feHueRef.current) {
        feHueRef.current.setAttribute('values', String(((ts - start) / 6000 * 360) % 360));
      }
      rafRef.current = requestAnimationFrame(tick);
    }
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, []);

  const now       = new Date();
  const month     = now.getMonth();
  const year      = now.getFullYear();
  const thisMonth = runs.filter(r => {
    const d = new Date(r.created_at);
    return d.getMonth() === month && d.getFullYear() === year;
  });

  function emailToName(email) {
    const local = email.split('@')[0];
    return local
      .split('.')
      .map(part => part.charAt(0).toUpperCase() + part.slice(1))
      .join(' ');
  }

  let cotmName = 'Veel pole pigistajaid';
  let cotmStat = '';
  if (thisMonth.length) {
    const counts = {};
    thisMonth.forEach(r => { counts[r.email] = (counts[r.email] || 0) + (r.file_count || 0); });
    const [email, files] = Object.entries(counts).sort((a, b) => b[1] - a[1])[0];
    cotmName = emailToName(email);
    cotmStat = `${files} faili pigistatud sel kuul`;
  }

  return (
    <Box mb="md">
      <Box
        style={{
          background: NAVY,
          borderRadius: 12,
          padding: '28px 32px',
          display: 'flex',
          alignItems: 'center',
          gap: 24,
          boxShadow: '0 2px 8px rgba(0,0,0,.1)',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* SVG filter for animated shadow */}
        <svg style={{ position: 'absolute', width: 0, height: 0, overflow: 'hidden' }}>
          <defs>
            <filter id="cotm-filter">
              <feTurbulence result="undulation" numOctaves="2" baseFrequency="0.00085,0.0034" seed="0" type="turbulence" />
              <feColorMatrix ref={feHueRef} in="undulation" type="hueRotate" values="180" />
              <feColorMatrix in="dist" result="circulation" type="matrix" values="4 0 0 0 1  4 0 0 0 1  4 0 0 0 1  1 0 0 0 0" />
              <feDisplacementMap in="SourceGraphic" in2="circulation" scale="64" result="dist" />
              <feDisplacementMap in="dist" in2="undulation" scale="64" result="output" />
            </filter>
          </defs>
        </svg>

        {/* Animated shadow overlay */}
        <Box
          style={{
            position: 'absolute',
            inset: -60,
            filter: 'url(#cotm-filter) blur(6px)',
            pointerEvents: 'none',
            zIndex: 0,
          }}
        >
          <Box
            style={{
              backgroundColor: 'rgba(247,117,42,0.38)',
              maskImage: "url('https://framerusercontent.com/images/ceBGguIpUU8luwByxuQz79t7To.png')",
              WebkitMaskImage: "url('https://framerusercontent.com/images/ceBGguIpUU8luwByxuQz79t7To.png')",
              maskSize: 'cover',
              WebkitMaskSize: 'cover',
              maskRepeat: 'no-repeat',
              WebkitMaskRepeat: 'no-repeat',
              maskPosition: 'center',
              WebkitMaskPosition: 'center',
              width: '100%',
              height: '100%',
            }}
          />
        </Box>

        {/* Confetti pieces */}
        {CONFETTI.map((p, i) => (
          <Box
            key={i}
            style={{
              position: 'absolute',
              width: p.s,
              height: p.s,
              left: p.x,
              top: p.y,
              borderRadius: p.odd ? '50%' : 2,
              background: COLORS[i],
              animation: `cpDrift ${p.odd ? '6s' : '8s'} ${p.d} ease-in-out infinite`,
              pointerEvents: 'none',
              zIndex: 1,
            }}
          />
        ))}

        {/* Trophy */}
        <Box
          style={{
            flexShrink: 0,
            width: 112,
            height: 112,
            position: 'relative',
            zIndex: 2,
            animation: 'trophyFloat 1.8s ease-in-out infinite',
          }}
        >
          <img
            src={trophySrc}
            alt="Trophy"
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'contain',
              filter: 'drop-shadow(0 4px 12px rgba(0,0,0,.3))',
            }}
          />
        </Box>

        {/* Text */}
        <Box style={{ position: 'relative', zIndex: 2 }}>
          <Badge color="orange" variant="filled" radius="xl" mb={8} tt="uppercase" style={{ color: NAVY }} styles={{ label: { fontWeight: 800 } }}>
            Kuu pigistaja
          </Badge>
          <Text fw={800} style={{ fontSize: 36, color: '#fff', paddingBottom: 4 }}>
            {cotmName}
          </Text>
          <Text size="sm" style={{ color: 'rgba(255,255,255,.65)' }}>
            {cotmStat}
          </Text>
        </Box>
      </Box>
    </Box>
  );
}
