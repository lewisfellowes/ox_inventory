import { Locale } from '../../store/locale';
import React from 'react';
import {
  FloatingFocusManager,
  FloatingOverlay,
  FloatingPortal,
  useDismiss,
  useFloating,
  useInteractions,
  useTransitionStyles,
} from '@floating-ui/react';

interface Props {
  infoVisible: boolean;
  setInfoVisible: React.Dispatch<React.SetStateAction<boolean>>;
}

interface ControlRowProps {
  keys: string[];
  label?: string;
}

const ControlRow: React.FC<ControlRowProps> = ({ keys, label }) => (
  <div className="useful-control-row">
    <div className="useful-control-keys">
      {keys.map((key, index) => (
        <React.Fragment key={`${key}-${index}`}>
          {index > 0 && <span className="useful-control-plus">+</span>}
          <span className="useful-control-key">{key}</span>
        </React.Fragment>
      ))}
    </div>

    {label && <span className="useful-control-label">{label}</span>}
  </div>
);

const UsefulControls: React.FC<Props> = ({ infoVisible, setInfoVisible }) => {
  const { refs, context } = useFloating({
    open: infoVisible,
    onOpenChange: setInfoVisible,
  });

  const dismiss = useDismiss(context, {
    outsidePressEvent: 'mousedown',
  });

  const { isMounted, styles } = useTransitionStyles(context);

  const { getFloatingProps } = useInteractions([dismiss]);

  return (
    <>
      {isMounted && (
        <FloatingPortal>
          <FloatingOverlay
            lockScroll
            className="useful-controls-dialog-overlay"
            data-open={infoVisible}
            style={styles}
          >
            <FloatingFocusManager context={context}>
              <div
                ref={refs.setFloating}
                {...getFloatingProps()}
                className="useful-controls-dialog"
                style={styles}
              >
                <div className="useful-controls-dialog-title">
                  <p>{Locale.ui_usefulcontrols || 'Useful controls'}</p>

                  <div
                    className="useful-controls-dialog-close"
                    onClick={() => setInfoVisible(false)}
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      height="1em"
                      viewBox="0 0 400 528"
                    >
                      <path d="M376.6 84.5c11.3-13.6 9.5-33.8-4.1-45.1s-33.8-9.5-45.1 4.1L192 206 56.6 43.5C45.3 29.9 25.1 28.1 11.5 39.4S-3.9 70.9 7.4 84.5L150.3 256 7.4 427.5c-11.3 13.6-9.5 33.8 4.1 45.1s33.8 9.5 45.1-4.1L192 306 327.4 468.5c11.3 13.6 31.5 15.4 45.1 4.1s15.4-31.5 4.1-45.1L233.7 256 376.6 84.5z" />
                    </svg>
                  </div>
                </div>

                <div className="useful-controls-content-wrapper">
                  <ControlRow
                    keys={['RMB']}
                    label={Locale.ui_rmb}
                  />

                  <ControlRow
                    keys={['ALT', 'LMB']}
                    label={Locale.ui_alt_lmb}
                  />

                  <ControlRow
                    keys={['CTRL', 'LMB']}
                    label={Locale.ui_ctrl_lmb}
                  />

                  <ControlRow
                    keys={['SHIFT', 'DRAG']}
                    label={Locale.ui_shift_drag}
                  />

                  <ControlRow
                    keys={['CTRL', 'SHIFT', 'LMB']}
                    label={Locale.ui_ctrl_shift_lmb}
                  />

                  <div className="useful-controls-brandmark">🐂</div>
                </div>
              </div>
            </FloatingFocusManager>
          </FloatingOverlay>
        </FloatingPortal>
      )}
    </>
  );
};

export default UsefulControls;