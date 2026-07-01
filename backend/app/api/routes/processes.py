"""
/api/processes — Process, SOP, Safety Rules master data endpoints.

GET  /api/processes                       → list all active processes
POST /api/processes/{id}/sops             → create new SOP
GET  /api/processes/{id}/sops             → SOPs for a process
GET  /api/processes/{id}/sops/{sop_id}    → SOP detail with steps
PUT  /api/processes/{id}/sops/{sop_id}    → update SOP fields + steps
GET  /api/processes/{id}/rule-sets        → safety rule sets for a process
GET  /api/processes/{id}/rule-sets/{rs_id} → rule set with items by category
"""
import json
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Process, Sop, SopStep, SafetyRuleSet, SafetyRuleItem


# ── Request schemas ──────────────────────────────────────────────────────────

class SopStepIn(BaseModel):
    step_no: int
    title: Optional[str] = None
    title_th: Optional[str] = None
    description: Optional[str] = None
    is_critical: bool = False


class SopCreate(BaseModel):
    code: str
    title: str
    title_th: Optional[str] = None
    version: str = "1.0"
    purpose: Optional[str] = None
    responsible: Optional[str] = None
    equipment: Optional[str] = None
    kpi: Optional[str] = None
    steps: List[SopStepIn] = []


class SopUpdate(BaseModel):
    title: Optional[str] = None
    title_th: Optional[str] = None
    version: Optional[str] = None
    purpose: Optional[str] = None
    responsible: Optional[str] = None
    equipment: Optional[str] = None
    kpi: Optional[str] = None
    status: Optional[str] = None
    safety_rules: Optional[str] = None
    steps: Optional[List[SopStepIn]] = None

router = APIRouter(prefix="/api/processes", tags=["processes"])


class ProcessCreate(BaseModel):
    code: str
    name: str
    name_th: Optional[str] = None
    description: Optional[str] = None


@router.get("")
def list_processes(db: Session = Depends(get_db)):
    procs = db.query(Process).filter(Process.active == True).order_by(Process.id).all()
    return [{"id": p.id, "code": p.code, "name": p.name, "name_th": p.name_th,
             "description": p.description} for p in procs]


@router.post("", status_code=201)
def create_process(body: ProcessCreate, db: Session = Depends(get_db)):
    if db.query(Process).filter(Process.code == body.code).first():
        raise HTTPException(status_code=409, detail=f"Process code '{body.code}' already exists")
    proc = Process(code=body.code, name=body.name, name_th=body.name_th, description=body.description, active=True)
    db.add(proc)
    db.commit()
    db.refresh(proc)
    return {"id": proc.id, "code": proc.code, "name": proc.name, "name_th": proc.name_th}


@router.delete("/{process_id}", status_code=204)
def delete_process(process_id: int, db: Session = Depends(get_db)):
    proc = db.get(Process, process_id)
    if not proc:
        raise HTTPException(status_code=404, detail="Process not found")
    proc.active = False  # soft delete
    db.commit()


@router.get("/sops/all")
def list_all_sops(db: Session = Depends(get_db)):
    """Return all SOPs across all processes (for SOP Management page)."""
    sops = (db.query(Sop, Process)
            .join(Process, Sop.process_id == Process.id)
            .filter(Sop.active == True)
            .order_by(Sop.id).all())
    return [{
        "id": s.id, "code": s.code, "title": s.title, "version": s.version,
        "status": s.status or "draft",
        "responsible": s.responsible, "process_id": p.id,
        "process_name": p.name, "process_code": p.code,
    } for s, p in sops]


@router.get("/{process_id}/sops")
def list_sops(process_id: int, db: Session = Depends(get_db)):
    sops = (db.query(Sop)
            .filter(Sop.process_id == process_id, Sop.active == True)
            .order_by(Sop.id).all())
    return [{"id": s.id, "code": s.code, "title": s.title, "title_th": s.title_th,
             "version": s.version, "purpose": s.purpose, "responsible": s.responsible,
             "equipment": s.equipment, "kpi": s.kpi} for s in sops]


@router.post("/{process_id}/sops", status_code=201)
def create_sop(process_id: int, body: SopCreate, db: Session = Depends(get_db)):
    proc = db.get(Process, process_id)
    if not proc:
        raise HTTPException(status_code=404, detail="Process not found")
    if db.query(Sop).filter(Sop.code == body.code).first():
        raise HTTPException(status_code=409, detail=f"SOP code '{body.code}' already exists")
    sop = Sop(
        process_id=process_id,
        code=body.code,
        title=body.title,
        title_th=body.title_th,
        version=body.version,
        purpose=body.purpose,
        responsible=body.responsible,
        equipment=body.equipment,
        kpi=body.kpi,
        active=True,
    )
    db.add(sop)
    db.flush()
    for s in body.steps:
        db.add(SopStep(sop_id=sop.id, step_no=s.step_no, title=s.title,
                       title_th=s.title_th, description=s.description, is_critical=s.is_critical))
    db.commit()
    db.refresh(sop)
    return {"id": sop.id, "code": sop.code, "title": sop.title,
            "version": sop.version, "process_id": process_id}


@router.put("/{process_id}/sops/{sop_id}")
def update_sop(process_id: int, sop_id: int, body: SopUpdate, db: Session = Depends(get_db)):
    sop = db.query(Sop).filter(Sop.id == sop_id, Sop.process_id == process_id).first()
    if not sop:
        raise HTTPException(status_code=404, detail="SOP not found")
    for field in ("title", "title_th", "version", "purpose", "responsible", "equipment", "kpi", "status", "safety_rules"):
        val = getattr(body, field)
        if val is not None:
            setattr(sop, field, val)
    if body.steps is not None:
        db.query(SopStep).filter(SopStep.sop_id == sop_id).delete()
        for s in body.steps:
            db.add(SopStep(sop_id=sop_id, step_no=s.step_no, title=s.title,
                           title_th=s.title_th, description=s.description, is_critical=s.is_critical))
    db.commit()
    db.refresh(sop)
    return {"id": sop.id, "code": sop.code, "title": sop.title, "version": sop.version}


@router.delete("/{process_id}/sops/{sop_id}", status_code=204)
def delete_sop(process_id: int, sop_id: int, db: Session = Depends(get_db)):
    sop = db.query(Sop).filter(Sop.id == sop_id, Sop.process_id == process_id).first()
    if not sop:
        raise HTTPException(status_code=404, detail="SOP not found")
    db.query(SopStep).filter(SopStep.sop_id == sop_id).delete()
    db.delete(sop)
    db.commit()


@router.get("/{process_id}/sops/{sop_id}")
def get_sop(process_id: int, sop_id: int, db: Session = Depends(get_db)):
    sop = db.query(Sop).filter(Sop.id == sop_id, Sop.process_id == process_id).first()
    if not sop:
        raise HTTPException(status_code=404, detail="SOP not found")
    steps = (db.query(SopStep).filter(SopStep.sop_id == sop_id)
             .order_by(SopStep.step_no).all())
    return {
        "id": sop.id, "code": sop.code, "title": sop.title, "title_th": sop.title_th,
        "version": sop.version, "purpose": sop.purpose, "responsible": sop.responsible,
        "equipment": sop.equipment, "kpi": sop.kpi, "status": sop.status or "draft",
        "safety_rules": sop.safety_rules or "[]",
        "steps": [{"step_no": s.step_no, "title": s.title, "title_th": s.title_th,
                   "description": s.description, "is_critical": s.is_critical} for s in steps],
    }


@router.get("/rules/all")
def list_all_safety_rules(db: Session = Depends(get_db)):
    """Aggregate all SOP-level safety rules across all processes."""
    rows = (db.query(Sop, Process)
            .join(Process, Sop.process_id == Process.id)
            .filter(Sop.active == True)
            .order_by(Sop.id).all())
    result = []
    for s, p in rows:
        try:
            rules = json.loads(s.safety_rules or "[]")
            if not isinstance(rules, list):
                continue
        except Exception:
            continue
        for r in rules:
            result.append({
                "id": r.get("id"),
                "text": r.get("text", ""),
                "severity": r.get("severity", "Medium"),
                "category": r.get("category", "action"),
                "sop_id": s.id, "sop_code": s.code, "sop_title": s.title,
                "process_id": p.id, "process_name": p.name, "process_code": p.code,
            })
    return result


@router.get("/{process_id}/rule-sets")
def list_rule_sets(process_id: int, db: Session = Depends(get_db)):
    sets = (db.query(SafetyRuleSet)
            .filter(SafetyRuleSet.process_id == process_id, SafetyRuleSet.active == True)
            .order_by(SafetyRuleSet.id).all())
    return [{"id": rs.id, "title": rs.title, "title_th": rs.title_th,
             "version": rs.version} for rs in sets]


@router.get("/{process_id}/rule-sets/{rs_id}")
def get_rule_set(process_id: int, rs_id: int, db: Session = Depends(get_db)):
    rs = db.query(SafetyRuleSet).filter(
        SafetyRuleSet.id == rs_id, SafetyRuleSet.process_id == process_id).first()
    if not rs:
        raise HTTPException(status_code=404, detail="Rule set not found")
    items = (db.query(SafetyRuleItem)
             .filter(SafetyRuleItem.rule_set_id == rs_id)
             .order_by(SafetyRuleItem.category, SafetyRuleItem.sort_order).all())

    # Group by category
    categories = {}
    for item in items:
        categories.setdefault(item.category, []).append({
            "id": item.id, "rule_text": item.rule_text, "rule_text_th": item.rule_text_th,
            "severity": item.severity, "is_prohibited": item.is_prohibited,
            "sub_section": item.sub_section, "sort_order": item.sort_order,
        })

    return {
        "id": rs.id, "title": rs.title, "title_th": rs.title_th, "version": rs.version,
        "categories": categories,
    }
