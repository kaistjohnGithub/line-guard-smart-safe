import json
from typing import Any


def _safe_text(value: Any, fallback: str = "Not available") -> str:
    if value is None:
        return fallback
    text = str(value).strip()
    return text or fallback


def _format_sop(sop_data: dict | None) -> str:
    if not sop_data:
        return "No SOP attached to this camera."

    parts = [
        f"Title: {_safe_text(sop_data.get('title_th') or sop_data.get('title'))}",
        f"Version: {_safe_text(sop_data.get('version'))}",
        f"Purpose: {_safe_text(sop_data.get('purpose'))}",
        f"Responsible: {_safe_text(sop_data.get('responsible'))}",
        f"Equipment: {_safe_text(sop_data.get('equipment'))}",
        f"KPI: {_safe_text(sop_data.get('kpi'))}",
    ]
    steps = sop_data.get("steps") or []
    if steps:
        step_lines = []
        for step in steps[:12]:
            title = _safe_text(step.get("title_th") or step.get("title"), fallback=f"Step {step.get('step_no', '?')}")
            desc = _safe_text(step.get("description"))
            critical = " [CRITICAL]" if step.get("is_critical") else ""
            step_lines.append(f"- Step {step.get('step_no', '?')}: {title}{critical} | {desc}")
        parts.append("Steps:\n" + "\n".join(step_lines))
    return "\n".join(parts)


def _format_rules(rule_data: dict | None, sop_data: dict | None) -> str:
    if rule_data and rule_data.get("categories"):
        lines = []
        for category, items in rule_data["categories"].items():
            if not items:
                continue
            lines.append(f"{category.upper()}:")
            for item in items[:8]:
                text = _safe_text(item.get("rule_text_th") or item.get("rule_text"))
                severity = _safe_text(item.get("severity"), fallback="medium")
                lines.append(f"- ({severity}) {text}")
        if lines:
            return "\n".join(lines)

    if sop_data and sop_data.get("safety_rules"):
        try:
            parsed = json.loads(sop_data["safety_rules"])
            if isinstance(parsed, list) and parsed:
                return "\n".join(
                    f"- ({_safe_text(item.get('severity'), fallback='medium')}) {_safe_text(item.get('text'))}"
                    for item in parsed[:12]
                    if isinstance(item, dict)
                ) or "No explicit safety rules found."
        except Exception:
            pass

    return "No safety rule set attached to this camera."


def _format_events(events: list[dict] | None) -> str:
    if not events:
        return "No recent events available."

    lines = []
    for event in events[:12]:
        event_type = _safe_text(event.get("event_type_label") or event.get("event_type"))
        severity = _safe_text(event.get("severity") or event.get("safety_status"), fallback="unknown")
        desc = _safe_text(event.get("description"))
        offset = event.get("video_offset_seconds")
        if offset is None:
            offset = event.get("timestamp_sec")
        when = f"{float(offset):.1f}s" if offset is not None else _safe_text(event.get("occurred_at"), fallback="time n/a")
        lines.append(f"- [{severity}] {event_type} @ {when}: {desc}")
    return "\n".join(lines)


def build_camera_chat_system_prompt(
    camera: dict,
    sop_data: dict | None = None,
    rule_data: dict | None = None,
    recent_events: list[dict] | None = None,
) -> str:
    camera_summary = _safe_text(camera.get("aiSummary"))
    process_info = "\n".join([
        f"Camera ID: {_safe_text(camera.get('id'))}",
        f"Camera Name: {_safe_text(camera.get('name'))}",
        f"Process: {_safe_text(camera.get('process'))}",
        f"Station: {_safe_text(camera.get('station'))}",
        f"Location: {_safe_text(camera.get('location'))}",
        f"Zone: {_safe_text(camera.get('zone'))}",
        f"Status: {_safe_text(camera.get('status'))}",
        f"Risk Label: {_safe_text(camera.get('risk'))}",
    ])

    sop_info = _format_sop(sop_data)
    rules_info = _format_rules(rule_data, sop_data)
    recent_event_info = _format_events(recent_events)

    return f"""You are ChatMe, an AI safety assistant for a smart factory camera monitoring system.

Primary role:
- Help operators and supervisors understand this camera's purpose, SOP, safety rules, and recent events.
- Answer only from the provided camera context and attached records.
- Support safe decisions, SOP compliance, and practical next actions.

Strict guardrails:
- Respond in Thai.
- Use only the information in Camera Context, Camera Metadata, SOP, Safety Rules, and Recent Events.
- If the answer is not supported by the provided context, say clearly that the information is not available from the current camera context.
- Do not invent facts, missing procedures, missing incident details, or root causes.
- Do not claim that you can currently see the live video feed.
- Only mention an observation if it appears explicitly in the provided recent events or context.
- If there is uncertainty, state it clearly.

Reasoning style:
- Prioritize worker safety and SOP compliance over convenience.
- Distinguish between:
  1. facts from context
  2. likely interpretation
  3. recommended next action
- If a risk or unsafe condition is relevant, explain why it matters and what should be checked next.
- Keep answers concise, practical, and easy for factory staff to use.

Preferred response format:
Summary:
- 1 to 3 short sentences

Evidence:
- Bullet points from camera context, SOP, rules, or recent events

Risk Level:
- low / medium / high / critical
- If risk level cannot be determined from context, say "unknown from current context"

Recommended Action:
- Specific next checks or actions for the operator or supervisor

If the user asks for:
- a summary: focus on the most important operational and safety points first
- SOP explanation: explain the relevant SOP steps and related precautions
- incident or risk analysis: focus on evidence, uncertainty, and next checks
- general questions outside this camera context: say that the information is not available from the current camera context

Camera Context / Summary:
{camera_summary}

Camera Metadata:
{process_info}

SOP:
{sop_info}

Safety Rules:
{rules_info}

Recent Events:
{recent_event_info}
"""
