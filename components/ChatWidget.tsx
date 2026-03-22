import React, { useState, useRef, useEffect } from 'react';

export interface ChatContext {
  title: string;
  content: string;
  [key: string]: any;
}

export interface ChatWidgetProps {
  apiUrl: string;
  contextExtractor?: () => ChatContext;
  title?: string;
  position?: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left';
  theme?: {
    primaryColor?: string;
    backgroundColor?: string;
    textColor?: string;
  };
}

const styles = {
  toggleButton: {
    position: 'fixed' as const,
    width: '64px',
    height: '64px',
    borderRadius: '50%',
    border: 'none',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: 'transform 0.2s, box-shadow 0.2s',
    zIndex: 1000,
  },
  chatWindow: {
    position: 'fixed' as const,
    width: '400px',
    height: '550px',
    borderRadius: '16px',
    display: 'flex',
    flexDirection: 'column' as const,
    boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
    zIndex: 1000,
    overflow: 'hidden',
  },
  header: {
    padding: '16px 20px',
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    color: 'white',
  },
  messagesContainer: {
    flex: 1,
    overflowY: 'auto' as const,
    padding: '16px',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '16px',
    background: 'linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%)',
  },
  messageRow: {
    display: 'flex',
    gap: '10px',
    maxWidth: '85%',
  },
  messageBubble: {
    padding: '12px 16px',
    borderRadius: '16px',
    fontSize: '14px',
    lineHeight: '1.5',
    wordBreak: 'break-word' as const,
    boxShadow: '0 1px 2px rgba(0, 0, 0, 0.05)',
  },
  inputContainer: {
    padding: '16px',
    borderTop: '1px solid #e5e7eb',
    background: 'white',
  },
  inputForm: {
    display: 'flex',
    gap: '8px',
    alignItems: 'center',
  },
  inputField: {
    flex: 1,
    padding: '12px 16px',
    border: '1px solid #e5e7eb',
    borderRadius: '12px',
    fontSize: '14px',
    outline: 'none',
    background: '#f9fafb',
  },
  sendButton: {
    width: '48px',
    height: '48px',
    borderRadius: '12px',
    border: 'none',
    color: 'white',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: 'transform 0.1s',
  },
  sendButtonDisabled: {
    opacity: 0.5,
    cursor: 'not-allowed',
  },
  avatar: {
    width: '32px',
    height: '32px',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  timestamp: {
    fontSize: '11px',
    color: '#9ca3af',
    marginTop: '4px',
    paddingHorizontal: '4px',
  },
  emptyState: {
    height: '100%',
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    justifyContent: 'center',
    textAlign: 'center' as const,
    padding: '24px',
  },
  backdrop: {
    position: 'fixed' as const,
    inset: 0,
    background: 'rgba(0, 0, 0, 0.2)',
    backdropFilter: 'blur(4px)',
    zIndex: 999,
  },
};

export const ChatWidget: React.FC<ChatWidgetProps> = ({
  apiUrl,
  contextExtractor,
  title = 'Chat Assistant',
  position = 'bottom-right',
  theme = {}
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string; timestamp: Date }>>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async () => {
    if (!input.trim()) return;

    const userMessage = input.trim();
    setInput('');
    setMessages(prev => [...prev, { role: 'user', content: userMessage, timestamp: new Date() }]);
    setIsLoading(true);

    try {
      let context = contextExtractor ? contextExtractor() : undefined;

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: userMessage, context }),
      });

      if (!response.ok) throw new Error('Failed to get response');

      const data = await response.json();
      setMessages(prev => [...prev, { role: 'assistant', content: data.response, timestamp: new Date() }]);
    } catch (error) {
      setMessages(prev => [...prev, { role: 'assistant', content: 'Sorry, something went wrong. Please try again.', timestamp: new Date() }]);
    } finally {
      setIsLoading(false);
    }
  };

  const primaryColor = theme.primaryColor || '#6366f1';
  const backgroundColor = theme.backgroundColor || '#ffffff';
  const textColor = theme.textColor || '#1f2937';

  const getPositionStyle = (): React.CSSProperties => {
    switch (position) {
      case 'bottom-right':
        return { bottom: '24px', right: '24px' };
      case 'bottom-left':
        return { bottom: '24px', left: '24px' };
      case 'top-right':
        return { top: '24px', right: '24px' };
      case 'top-left':
        return { top: '24px', left: '24px' };
      default:
        return { bottom: '24px', right: '24px' };
    }
  };

  const getWindowPositionStyle = (): React.CSSProperties => {
    switch (position) {
      case 'bottom-right':
        return { bottom: '100px', right: '24px' };
      case 'bottom-left':
        return { bottom: '100px', left: '24px' };
      case 'top-right':
        return { top: '100px', right: '24px' };
      case 'top-left':
        return { top: '100px', left: '24px' };
      default:
        return { bottom: '100px', right: '24px' };
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <>
      {/* Toggle Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        style={{
          ...styles.toggleButton,
          ...getPositionStyle(),
          background: `linear-gradient(135deg, ${primaryColor} 0%, ${primaryColor}dd 100%)`,
          boxShadow: `0 8px 32px ${primaryColor}40`,
        }}
        aria-label="Toggle chat"
        onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.1)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
      >
        {isOpen ? (
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M6 18L18 6M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        ) : (
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ animation: 'pulse 2s infinite' }}>
            <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        )}
      </button>

      {/* Backdrop */}
      {isOpen && (
        <div
          style={styles.backdrop}
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Chat Window */}
      {isOpen && (
        <div
          style={{
            ...styles.chatWindow,
            ...getWindowPositionStyle(),
            backgroundColor,
          }}
        >
          {/* Header */}
          <div
            style={{
              ...styles.header,
              background: `linear-gradient(135deg, ${primaryColor} 0%, ${primaryColor}cc 100%)`,
            }}
          >
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '50%',
              background: 'rgba(255, 255, 255, 0.2)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: '18px' }}>{title}</div>
              <div style={{ fontSize: '14px', opacity: 0.8, display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  background: '#4ade80',
                  animation: 'pulse 2s infinite',
                }} />
                Online
              </div>
            </div>
            <button
              onClick={() => setIsOpen(false)}
              style={{
                width: '32px',
                height: '32px',
                borderRadius: '50%',
                border: 'none',
                background: 'rgba(255, 255, 255, 0.2)',
                color: 'white',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
              aria-label="Close chat"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M6 18L18 6M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>

          {/* Messages */}
          <div style={styles.messagesContainer}>
            {messages.length === 0 && (
              <div style={styles.emptyState}>
                <div style={{
                  width: '80px',
                  height: '80px',
                  borderRadius: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginBottom: '16px',
                  backgroundColor: `${primaryColor}20`,
                }}>
                  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke={primaryColor} strokeWidth="1.5">
                    <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
                <h4 style={{ fontWeight: 600, fontSize: '18px', marginBottom: '8px', color: textColor }}>Welcome! 👋</h4>
                <p style={{ color: '#6b7280', fontSize: '14px', maxWidth: '280px' }}>
                  I'm here to help answer questions about this page. What would you like to know?
                </p>
              </div>
            )}

            {messages.map((msg, idx) => (
              <div
                key={idx}
                style={{
                  display: 'flex',
                  justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
                }}
              >
                <div style={{
                  ...styles.messageRow,
                  flexDirection: msg.role === 'user' ? 'row-reverse' : 'row',
                }}>
                  {/* Avatar */}
                  <div style={{
                    ...styles.avatar,
                    background: msg.role === 'user' ? '#d1d5db' : `${primaryColor}20`,
                  }}>
                    {msg.role === 'user' ? (
                      <svg width="16" height="16" viewBox="0 0 20 20" fill="#4b5563">
                        <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd" />
                      </svg>
                    ) : (
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={primaryColor} strokeWidth="2">
                        <path d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    )}
                  </div>

                  {/* Message bubble */}
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <div
                      style={{
                        ...styles.messageBubble,
                        backgroundColor: msg.role === 'user' ? primaryColor : '#ffffff',
                        color: msg.role === 'user' ? '#ffffff' : textColor,
                        borderRadius: msg.role === 'user'
                          ? '16px 16px 4px 16px'
                          : '16px 16px 16px 4px',
                      }}
                    >
                      {msg.content}
                    </div>
                    <span style={styles.timestamp}>
                      {formatTime(msg.timestamp)}
                    </span>
                  </div>
                </div>
              </div>
            ))}

            {isLoading && (
              <div style={{ display: 'flex', justifyContent: 'flex-start' }}>
                <div style={styles.messageRow}>
                  <div style={{
                    ...styles.avatar,
                    background: `${primaryColor}20`,
                  }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={primaryColor} strokeWidth="2">
                      <path d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </div>
                  <div style={{
                    ...styles.messageBubble,
                    backgroundColor: '#ffffff',
                    borderRadius: '16px 16px 16px 4px',
                    padding: '12px 16px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                  }}>
                    <div style={{
                      width: '8px',
                      height: '8px',
                      borderRadius: '50%',
                      backgroundColor: primaryColor,
                      animation: 'bounce 1s infinite',
                    }} />
                    <div style={{
                      width: '8px',
                      height: '8px',
                      borderRadius: '50%',
                      backgroundColor: primaryColor,
                      animation: 'bounce 1s infinite 0.15s',
                    }} />
                    <div style={{
                      width: '8px',
                      height: '8px',
                      borderRadius: '50%',
                      backgroundColor: primaryColor,
                      animation: 'bounce 1s infinite 0.3s',
                    }} />
                  </div>
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Input */}
          <div style={styles.inputContainer}>
            <form
              onSubmit={(e) => { e.preventDefault(); sendMessage(); }}
              style={styles.inputForm}
            >
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Type your message..."
                style={{
                  ...styles.inputField,
                  color: textColor,
                }}
              />
              <button
                type="submit"
                disabled={!input.trim() || isLoading}
                style={{
                  ...styles.sendButton,
                  ...(!input.trim() || isLoading ? styles.sendButtonDisabled : {}),
                  background: `linear-gradient(135deg, ${primaryColor} 0%, ${primaryColor}cc 100%)`,
                  boxShadow: `0 4px 14px ${primaryColor}40`,
                }}
                onMouseEnter={(e) => {
                  if (input.trim() && !isLoading) {
                    e.currentTarget.style.transform = 'scale(1.05)';
                  }
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'scale(1)';
                }}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </form>
            <p style={{ fontSize: '11px', color: '#9ca3af', marginTop: '8px', textAlign: 'center' }}>
              Powered by AI • Responses may vary
            </p>
          </div>

          <style>{`
            @keyframes pulse {
              0%, 100% { opacity: 1; }
              50% { opacity: 0.5; }
            }
            @keyframes bounce {
              0%, 100% { transform: translateY(0); }
              50% { transform: translateY(-4px); }
            }
          `}</style>
        </div>
      )}
    </>
  );
};

export default ChatWidget;
