import React, { useMemo } from 'react';

const WeightBar: React.FC<{
  percent: number;
  durability?: boolean;
}> = ({ percent, durability }) => {
  const color = useMemo(() => {
    if (!durability) {
      return 'linear-gradient(90deg, #24d9df 0%, #42e8ed 100%)';
    }

    if (percent <= 25) {
      return '#e5656b';
    }

    if (percent <= 55) {
      return '#e2b85d';
    }

    return '#5fd49a';
  }, [durability, percent]);

  return (
    <div className={durability ? 'durability-bar' : 'weight-bar'}>
      <div
        style={{
          visibility: percent > 0 ? 'visible' : 'hidden',
          height: '100%',
          width: `${percent}%`,
          background: color,
          transition: 'background 0.3s ease, width 0.3s ease',
        }}
      />
    </div>
  );
};

export default WeightBar;