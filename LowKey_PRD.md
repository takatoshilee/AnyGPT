# Product Requirements Document: LowKey

## Executive Summary

**Product Name:** LowKey
**Version:** 1.0.0
**Date:** January 2025
**Author:** Product Team
**Status:** Ready for Development

### Vision Statement
LowKey is an invisible AI assistant that lives in your macOS menu bar, providing instant text transformation through LLMs with a single hotkey—no context switching required.

### Problem Statement
Knowledge workers constantly need to transform text (summarize, rewrite, translate, etc.) but current solutions require:
- Switching to a browser or separate app
- Copy-pasting text manually multiple times
- Waiting for interfaces to load
- Breaking concentration and workflow

### Solution
A zero-friction macOS utility that processes selected text through AI models with a single hotkey press, returning results directly to the clipboard or cursor position—keeping users in their flow state.

---

## Product Overview

### Target Users

**Primary Persona: Knowledge Worker**
- Writers, developers, researchers, consultants
- Works with text 4+ hours daily
- Values keyboard shortcuts and efficiency
- Already uses AI tools but wants faster access
- macOS power user comfortable with system preferences

**Secondary Persona: Content Creator**
- Social media managers, marketers, bloggers
- Needs quick text variations and rewrites
- Values speed over advanced features
- Prefers minimal configuration

### Key Use Cases

1. **Quick Rewriting**
   - User selects paragraph in email
   - Presses hotkey
   - Text is instantly rewritten professionally

2. **Code Explanation**
   - Developer selects code snippet
   - Presses hotkey with "explain" prompt
   - Gets plain English explanation

3. **Translation**
   - User selects foreign text
   - Presses hotkey with translation prompt
   - Gets instant translation

4. **Summarization**
   - Researcher selects long article text
   - Presses hotkey
   - Gets concise summary

### Success Metrics

- **Activation Rate**: 80% of downloaders configure API key within 24 hours
- **Daily Active Usage**: 70% use the hotkey at least once per day
- **Response Time**: 95% of requests complete in <3 seconds
- **Error Rate**: <1% of API calls fail
- **Retention**: 60% still actively using after 30 days

---

## Functional Requirements

### Core Features (MVP)

#### 1. Global Hotkey Trigger
- **Default**: ⌘⌥` (Command+Option+Backtick)
- **Customizable**: User can rebind to any key combination
- **Conflict Detection**: Warns if hotkey conflicts with system/app shortcuts
- **Visual Feedback**: Menu bar icon briefly highlights when triggered

#### 2. Text Processing Pipeline
```
Trigger → Copy Selection → Process via LLM → Return Result → Optional Paste
```
- **Step 1**: Synthetic ⌘C to copy current selection
- **Step 2**: Read plain text from system clipboard
- **Step 3**: Send to OpenAI Chat Completions API
- **Step 4**: Place response on clipboard
- **Step 5**: Optional synthetic ⌘V to paste

#### 3. Menu Bar Presence
- **Icon**: Minimalist "⌘" symbol or dot
- **States**:
  - Idle (default color)
  - Processing (animated/pulsing)
  - Error (red tint for 2 seconds)
- **Click Action**: Opens preferences popover
- **Right-Click**: Quick actions menu

#### 4. Preferences Interface

**General Tab:**
- Hotkey configuration (with recording button)
- Auto-paste toggle (default: off)
- Sound on completion toggle (default: on)
- Launch at login toggle (default: off)

**Model Tab:**
- Model selection dropdown:
  - gpt-4o-mini (default)
  - gpt-4o
  - gpt-3.5-turbo
  - o1-mini
  - Custom model (text field)
- System prompt editor (multiline, 500 char limit)
- Temperature slider (0.0-2.0, default: 0.7)
- Test button with sample text

**API Key Tab:**
- Secure text field with show/hide toggle
- Validate button (tests with minimal API call)
- Status indicator (Valid/Invalid/Checking)
- "Get API Key" link to OpenAI

**Advanced Tab:**
- Response timeout (5-60s, default: 20s)
- Max input length (1000-10000 chars, default: 4000)
- Retry attempts (0-3, default: 2)
- Debug logging toggle
- "Reveal Logs" button
- "Reset to Defaults" button

#### 5. Notifications
- **Success**: "LowKey — In: 124 chars • Out: 88 chars"
- **Errors**: "No text selected", "API key missing", "Network error"
- **Style**: Native macOS notifications
- **Duration**: 2 seconds auto-dismiss

### Non-Functional Requirements

#### Performance
- **Hotkey Response**: <50ms to initiate pipeline
- **API Timeout**: 20 seconds default, user configurable
- **Memory Usage**: <50MB resident memory
- **CPU Usage**: <1% when idle
- **Startup Time**: <2 seconds to menu bar appearance

#### Security
- **API Key Storage**: macOS Keychain (never in plain text)
- **Network**: HTTPS only, certificate pinning for OpenAI
- **Clipboard**: Clear sensitive data after 60 seconds (optional)
- **Logging**: No user content logged unless debug mode enabled
- **Sandboxing**: Minimal entitlements, no unnecessary permissions

#### Reliability
- **Error Recovery**: Exponential backoff on API failures
- **Graceful Degradation**: Always copy something to clipboard
- **Crash Recovery**: Auto-restart on unexpected termination
- **Data Persistence**: Settings survive app updates

#### Accessibility
- **VoiceOver**: Full support for preferences UI
- **Keyboard Navigation**: All features accessible without mouse
- **High Contrast**: Respects system accessibility settings
- **Text Size**: Follows system text size preferences

#### Compatibility
- **macOS Versions**: 12.0 (Monterey) through 15.0 (Latest)
- **Architectures**: Universal Binary (Intel + Apple Silicon)
- **Languages**: English (v1.0), expandable architecture
- **Display**: Retina and non-Retina support

---

## User Experience

### First-Run Experience
1. **Welcome Window**
   - Brief app explanation
   - "Grant Accessibility" button → System Preferences
   - "Add API Key" button → Preferences

2. **Accessibility Permission**
   - Clear explanation why needed
   - Direct button to System Preferences
   - Visual guide showing exact toggles

3. **API Key Setup**
   - Link to OpenAI API page
   - Paste field with validation
   - Test button to verify

4. **Quick Tutorial**
   - Animated GIF showing usage
   - Try it now with sample text
   - Skip/Complete button

### Error States

**No Selection**
- Notification: "Nothing selected"
- Clipboard: "Please select text first"

**No API Key**
- Opens Preferences to API Key tab
- Field focused and highlighted

**Network Error**
- Notification: "Network error - check connection"
- Clipboard: Contains specific error for debugging

**Rate Limited**
- Notification: "Too many requests - waiting..."
- Auto-retry with backoff

**Invalid Response**
- Notification: "Unexpected response"
- Clipboard: Raw response for user debugging

### Privacy & Trust

#### Data Handling
- **Local Processing**: All text processing happens on device
- **Direct API Calls**: No proxy servers or analytics
- **No Telemetry**: Zero tracking or usage analytics
- **Session Only**: No persistent storage of prompts/responses
- **User Control**: All data erasable via preferences

#### Permissions Required
1. **Accessibility**: For synthetic keyboard events
2. **Notifications**: For completion feedback (optional)

---

## Technical Architecture

### Component Overview
```
┌─────────────────────┐
│   Menu Bar (UI)     │
├─────────────────────┤
│  Hotkey Manager     │
├─────────────────────┤
│   Core Pipeline     │
├──────────┬──────────┤
│ Clipboard │ OpenAI   │
│  Service  │ Client   │
├──────────┼──────────┤
│ Keychain │ Logger   │
│  Service  │ Service  │
└──────────┴──────────┘
```

### API Integration

**OpenAI Chat Completions**
```http
POST https://api.openai.com/v1/chat/completions

Headers:
  Authorization: Bearer <API_KEY>
  Content-Type: application/json

Body:
{
  "model": "gpt-4o-mini",
  "messages": [
    {"role": "system", "content": "<SYSTEM_PROMPT>"},
    {"role": "user", "content": "<SELECTED_TEXT>"}
  ],
  "temperature": 0.7,
  "max_tokens": 500
}
```

### Data Flow
1. User selects text in any application
2. User presses configured hotkey
3. App sends synthetic ⌘C to copy selection
4. App reads clipboard content
5. App validates content (not empty, under limit)
6. App retrieves API key from Keychain
7. App sends request to OpenAI
8. App receives response
9. App places response on clipboard
10. App optionally sends synthetic ⌘V to paste
11. App shows notification with character counts

---

## Release Strategy

### MVP (v1.0)
- Core hotkey functionality
- Basic preferences
- OpenAI integration
- Menu bar presence
- Error handling

### v1.1 (2 weeks post-launch)
- Multiple hotkeys for different prompts
- Prompt templates/presets
- History (last 10 operations)
- Improved error messages

### v1.2 (1 month post-launch)
- Multiple LLM providers (Anthropic, Google)
- Custom API endpoints
- Export/import settings
- Keyboard shortcut recorder improvement

### v2.0 (3 months post-launch)
- Floating widget option
- Stream responses in real-time
- Context awareness (app-specific prompts)
- Team/enterprise features

---

## Success Criteria

### Launch Readiness Checklist
- [ ] Hotkey triggers reliably in all applications
- [ ] API key stored securely in Keychain
- [ ] Errors handled gracefully with user feedback
- [ ] Preferences persist across app restarts
- [ ] Memory usage stays under 50MB
- [ ] CPU usage under 1% when idle
- [ ] Accessibility permissions clearly requested
- [ ] All UI elements accessible via VoiceOver
- [ ] Universal binary runs on Intel and Apple Silicon
- [ ] No crashes in 100 consecutive operations

### Quality Metrics
- **Crash-free rate**: >99.9%
- **API success rate**: >99%
- **Response time (p95)**: <3 seconds
- **Memory leaks**: Zero
- **Accessibility score**: 100%

---

## Support & Documentation

### User Documentation
- Quick Start Guide (README)
- Troubleshooting FAQ
- Video tutorial (2 minutes)
- Keyboard shortcuts reference

### Developer Documentation
- Architecture overview
- API integration guide
- Build and deployment instructions
- Contributing guidelines

### Support Channels
- GitHub Issues (primary)
- Email support (premium)
- Discord community (future)

---

## Appendix

### Competitive Analysis

**Raycast AI**
- Pros: Powerful, integrated with launcher
- Cons: Requires full Raycast, subscription model

**TextSoap**
- Pros: Extensive text processing
- Cons: Not AI-powered, complex interface

**PopClip**
- Pros: Visual selection actions
- Cons: Not keyboard-driven, limited AI integration

**LowKey Advantages**
- Truly invisible (keyboard-only)
- Direct LLM integration
- Minimal resource usage
- One-time purchase model (planned)

### Technical Decisions

**Why AppKit over SwiftUI**
- Better menu bar support
- More stable on older macOS versions
- Finer control over hotkey handling

**Why OpenAI First**
- Most mature API
- Best price/performance (gpt-4o-mini)
- Extensive documentation

**Why Keychain over Files**
- OS-level security
- Encrypted by default
- Survives app reinstalls

### Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| API Rate Limits | High | Exponential backoff, user quotas |
| API Price Changes | Medium | Configurable models, provider abstraction |
| OS Permission Changes | High | Clear documentation, fallback methods |
| Hotkey Conflicts | Low | Conflict detection, multiple options |
| Security Breach | High | Keychain storage, no telemetry |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 2025 | Product Team | Initial PRD |

---

## Approval

**Product Owner:** ___________________ Date: ___________

**Engineering Lead:** _________________ Date: ___________

**Design Lead:** _____________________ Date: ___________