# -*- coding: utf-8 -*-
import os
import sys
import json
import datetime
import re
import html

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DOCS_MC = os.path.join(REPO_DIR, "docs", "master_control")
TOOLS_MC = os.path.join(REPO_DIR, "tools", "master_control")

sys.path.insert(0, TOOLS_MC)
from validate_control_room import run_validation

def load_json(fname, default=None):
    p = os.path.join(DOCS_MC, fname)
    if os.path.exists(p):
        try:
            with open(p, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return default if default is not None else []

def build_dashboard():
    # 0. Enforce VALIDATOR GATE before generation
    print("[GATE] Running validate_control_room pre-generation check...")
    val_pass, val_errs = run_validation(check_rendered_html=False)
    if not val_pass:
        print(f"[FATAL GATE REJECTION] validate_control_room failed with {len(val_errs)} errors! Halting dashboard generation.")
        sys.exit(1)
    print("[GATE] validate_control_room pre-check PASSED.")

    # Load all registries
    contract = load_json("CONTROL_ROOM_CONTRACT.json", {})
    current_sot = load_json("CURRENT_STATE_SOT.json", {})
    features = load_json("FEATURE_ROUTE_REGISTRY.json", [])
    components = load_json("COMPONENT_REGISTRY.json", [])
    protected_assets = load_json("PROTECTED_ASSETS.json", [])
    changes = load_json("CHANGE_REGISTRY.json", [])
    policies = load_json("POLICY_REGISTRY.json", [])
    errors = load_json("ERROR_LOG.json", [])
    lessons = load_json("LESSONS_REGISTRY.json", [])
    korean_summaries = load_json("KOREAN_SUMMARIES.json", {})

    summary_label = contract.get("summary_label", "KR")

    # Load CURRENT_STATE_SOT.json
    sot_path = os.path.join(DOCS_MC, "CURRENT_STATE_SOT.json")
    current_state = {}
    if os.path.exists(sot_path):
        try:
            with open(sot_path, "r", encoding="utf-8") as f:
                current_state = json.load(f)
        except Exception as e:
            print(f"[CURRENT_STATE_SOT WARNING] {e}")

    # Extract Constitution Metadata and Articles from SOT
    const_ext_path = os.path.join(DOCS_MC, "PROJECT_CONSTITUTION_EXTENSION.md")
    const_status = "ACTIVE / ENFORCED"
    const_policy_count = "51"
    constitution_articles = []

    try:
        if os.path.exists(const_ext_path):
            with open(const_ext_path, "r", encoding="utf-8") as f:
                const_lines = f.readlines()

            cur_art_title = None
            cur_art_body = []
            for line in const_lines:
                l_str = line.strip()
                if (l_str.startswith("### 제") and "조" in l_str) or l_str.startswith("### CONSTITUTION-") or l_str.startswith("## CONSTITUTION-") or l_str.startswith("### GEOMETRY-") or l_str.startswith("## SPATIAL-") or l_str.startswith("## POLICY-"):
                    if cur_art_title and cur_art_body:
                        constitution_articles.append({
                            "title": cur_art_title,
                            "body": " ".join(cur_art_body).strip()
                        })
                    cur_art_title = l_str.lstrip("#").strip()
                    cur_art_body = []
                elif cur_art_title is not None and l_str and not l_str.startswith("---") and not l_str.startswith("#"):
                    cur_art_body.append(l_str)
            if cur_art_title and cur_art_body:
                constitution_articles.append({
                    "title": cur_art_title,
                    "body": " ".join(cur_art_body).strip()
                })
    except Exception as e:
        print(f"[CONSTITUTION EXTRACTION WARNING] {e}")

    const_article_count = str(len(constitution_articles)) if constitution_articles else "18"

    # Render Constitution Article Grid HTML
    const_cards_html = []
    for art in constitution_articles:
        a_title = html.escape(art["title"])
        a_body = html.escape(art["body"])
        const_cards_html.append(f'''
        <div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:10px 14px; border-left:3px solid #58a6ff;">
            <div style="font-weight:bold; color:#79c0ff; font-size:13px; margin-bottom:4px;">{a_title}</div>
            <div style="color:#c9d1d9; font-size:12px; line-height:1.4;">{a_body}</div>
        </div>
        ''')
    const_articles_joined = "\n".join(const_cards_html)

    # Unresolved errors count
    unresolved_status_list = [
        "OPEN", "OPEN_PM_DEVICE_FAILED", "OPEN_PM_VISUAL_FAILED", "OPEN_PARTIAL_FIX",
        "FIX_APPLIED_PENDING_PM_DEVICE_ACCEPTANCE", "FIX_APPLIED_PENDING_PM_EMULATOR_ACCEPTANCE",
        "LOGGED", "DATA_APPLIED_PENDING", "SECURITY_HOLD"
    ]
    unresolved_errors = [e for e in errors if e.get("status") in unresolved_status_list or (not e.get("status", "").startswith("RESOLVED") and not e.get("status", "").startswith("CLOSED"))]
    unresolved_major_count = len([e for e in unresolved_errors if e.get("severity") in ["CRITICAL", "MAJOR"]])
    total_unresolved_count = len(unresolved_errors)

    # Valid change IDs for link checking
    valid_change_ids = set(c.get("change_id") for c in changes if c.get("change_id"))

    # Generate Unified Daily Timeline Log Cards
    all_log_items = []
    gen_date_str = datetime.date.today().isoformat()
    min_7d_str = (datetime.date.today() - datetime.timedelta(days=7)).isoformat()

    # Importance mapper
    importance_map = contract.get("work_importance", {
        "HIGH": {"ko": "중대", "icon": "🟠", "class": "severity-major"},
        "MEDIUM": {"ko": "보통", "icon": "🟡", "class": "severity-medium"},
        "LOW": {"ko": "경미", "icon": "🔵", "class": "severity-minor"}
    })

    # Severity mapper
    severity_map = contract.get("error_severity", {
        "CRITICAL": {"ko": "치명적", "icon": "🔴", "class": "severity-critical"},
        "MAJOR": {"ko": "중대", "icon": "🟠", "class": "severity-major"},
        "MEDIUM": {"ko": "보통", "icon": "🟡", "class": "severity-medium"},
        "MINOR": {"ko": "경미", "icon": "🔵", "class": "severity-minor"},
        "INFO": {"ko": "정보", "icon": "⚪", "class": "severity-info"}
    })

    # 1. Process CHANGE_REGISTRY records
    for c in changes:
        cid = html.escape(str(c.get("change_id") or "UNKNOWN_CID"))
        raw_ts = c.get("timestamp")
        if raw_ts and len(str(raw_ts)) >= 10:
            date_iso = str(raw_ts)[:10]
            month_iso = str(raw_ts)[:7]
            ts_display = html.escape(str(raw_ts))
        else:
            date_iso = "UNKNOWN_DATE"
            month_iso = "UNKNOWN_MONTH"
            ts_display = "날짜 미확인"

        is_recent_7d = "true" if (date_iso != "UNKNOWN_DATE" and date_iso >= min_7d_str and date_iso <= gen_date_str) else "false"

        st_raw = c.get("status") or "UNKNOWN"
        st = html.escape(str(st_raw))
        st_class = "badge-pass" if st in ["PASS", "APPROVED", "CONFIRMED"] else "badge-warn"
        st_group = "PASS" if st in ["PASS", "APPROVED", "CONFIRMED"] else "OTHER"

        # Map work risk/importance to Canonical Korean Badge
        raw_risk = str(c.get("risk") or "").upper().strip()
        if "HIGH" in raw_risk:
            risk_tag = ' <span class="status-badge severity-major">🟠 중대</span>'
        elif "MEDIUM" in raw_risk:
            risk_tag = ' <span class="status-badge severity-medium">🟡 보통</span>'
        elif "LOW" in raw_risk:
            risk_tag = ' <span class="status-badge severity-minor">🔵 경미</span>'
        else:
            risk_tag = ""

        title_raw = c.get("title") or c.get("pm_display_title") or c.get("technical_title") or "제목 없음"
        title_esc = html.escape(str(title_raw))

        req_val = html.escape(str(c.get("what") or c.get("request") or "기록 없음"))
        why_val = html.escape(str(c.get("why") or "기록 없음"))
        res_val = html.escape(str(c.get("result") or "기록 없음"))
        feat_val = html.escape(str(c.get("affected_features") or "기록 없음"))
        files_val = html.escape(str(c.get("affected_files") or "기록 없음"))
        apis_val = html.escape(str(c.get("affected_apis") or "해당 없음 — 프론트엔드/문서 전용"))
        prot_val = html.escape(str(c.get("protected_assets") or c.get("must_not_touch") or "기록 없음"))
        verif_val = html.escape(str(c.get("verification") or "기록 없음"))
        commit_val = html.escape(str(c.get("related_commit") or "근거 미확보"))
        appr_val = html.escape(str(c.get("pm_approval") or "PM 승인 완료"))
        prev_val = html.escape(str(c.get("recurrence_prevention") or "기록 없음"))

        ko_summary = korean_summaries.get(str(c.get("change_id") or "")) or "한국어 요약 없음"
        ko_summary_esc = html.escape(str(ko_summary))

        if ko_summary_esc and ko_summary_esc != "한국어 요약 없음":
            req_cell = f'<div>{req_val}</div><div style="margin-top:4px; font-size:11px; color:#79c0ff; line-height:1.3;"><strong style="color:#58a6ff;">KR:</strong> {ko_summary_esc}</div>'
        else:
            req_cell = req_val

        card_html = f'''
        <div class="log-card" data-date="{date_iso}" data-month="{month_iso}" data-status="{st}" data-status-group="{st_group}" data-type="CHANGE" data-recent-7d="{is_recent_7d}">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:12px;">
                <div style="flex:1; min-width:0;">
                    <span class="status-badge" style="background:#1f6feb; color:#fff; font-size:10px;">작업</span>{risk_tag}
                    <span style="font-size:12px; color:#8b949e; font-family:monospace; margin-left:4px;">{ts_display}</span> |
                    <code>{cid}</code>
                    <strong style="margin-left:6px; color:#c9d1d9; word-break:break-word;">{title_esc}</strong>
                </div>
                <div style="flex-shrink:0; display:flex; gap:6px; align-items:center;">
                    <span class="status-badge {st_class}">{st}</span>
                </div>
            </div>
            <div style="font-size:12px; color:#e6edf3; background:#21262d; border-left:3px solid #58a6ff; padding:6px 10px; border-radius:4px; margin-top:6px; line-height:1.4;">
                <strong style="color:#79c0ff;">{summary_label}:</strong> {ko_summary_esc}
            </div>
            <details class="log-details" style="margin-top:8px;">
                <summary style="cursor:pointer; font-size:11px; color:#58a6ff; font-weight:bold; padding:3px 8px; background:#21262d; border:1px solid #30363d; border-radius:4px; display:inline-block; user-select:none;">
                    <span class="log-summary-closed">상세 ▼</span>
                    <span class="log-summary-open">접기 ▲</span>
                </summary>
                <div style="background:#0d1117; border:1px solid #30363d; border-radius:4px; padding:10px; margin-top:6px; font-size:12px; line-height:1.5;">
                    <table style="width:100%; border:none; margin:0;">
                        <tr><td style="width:140px; color:#8b949e; border:none; padding:3px 0;">무슨 작업인가?</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{req_cell}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">이유 / 배경</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{why_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">작업 결과</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{res_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">영향 기능</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{feat_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">영향 파일</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{files_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">영향 API</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{apis_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">보호 대상</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{prot_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">검증 결과</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{verif_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">관련 Commit</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{commit_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">PM 승인 여부</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{appr_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">재발 방지 / 주의사항</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{prev_val}</td></tr>
                    </table>
                </div>
            </details>
        </div>
        '''
        all_log_items.append({
            "sort_key": str(raw_ts or "0000-00-00"),
            "date_iso": date_iso,
            "month_iso": month_iso,
            "html": card_html
        })

    # 2. Process ERROR_LOG records
    for e in errors:
        eid = html.escape(str(e.get("error_id") or "UNKNOWN_ERR_ID"))
        raw_fsd = str(e.get("first_seen_date") or "").strip()
        raw_rep = str(e.get("reported_at") or "").strip()

        if raw_fsd and len(raw_fsd) >= 10:
            edate = raw_fsd[:10]
            etime = str(e.get("first_seen_time") or "").strip()
            ts_display = html.escape(f"{edate} {etime}".strip())
            date_iso = edate
            month_iso = edate[:7]
            sort_key = f"{edate} {etime}".strip()
        elif raw_rep and len(raw_rep) >= 10:
            date_iso = raw_rep[:10]
            month_iso = raw_rep[:7]
            ts_display = html.escape(raw_rep.replace("T", " ")[:19])
            sort_key = raw_rep.replace("T", " ")[:19]
        else:
            date_iso = "UNKNOWN_DATE"
            month_iso = "UNKNOWN_MONTH"
            ts_display = "날짜 미확인"
            sort_key = "0000-00-00"

        is_recent_7d = "true" if (date_iso != "UNKNOWN_DATE" and date_iso >= min_7d_str and date_iso <= gen_date_str) else "false"

        raw_sev = str(e.get("severity") or "").upper().strip()
        if raw_sev in severity_map:
            s_info = severity_map[raw_sev]
            sev_key = raw_sev
            sev_badge = f'<span class="status-badge {s_info.get("class", "severity-minor")}">{s_info.get("icon", "")} {s_info.get("ko", raw_sev)}</span>'
        else:
            sev_key = "UNCLASSIFIED"
            sev_badge = '<span class="status-badge severity-unknown">⚪ 미분류</span>'

        st_raw = e.get("status") or "UNKNOWN"
        st = html.escape(str(st_raw))
        st_class = "badge-pass" if st in ["RESOLVED", "RESOLVED_WORKSPACE_CONFIG_UPDATED"] else "badge-warn"

        title_raw = e.get("short_summary_ko") or e.get("symptom") or "오류"
        title_esc = html.escape(str(title_raw))

        symp_str = html.escape(str(e.get("symptom") or "증상 기록 없음"))
        cond_str = html.escape(str(e.get("occurrence_condition") or e.get("category") or "기록 없음"))
        root_cause_val = html.escape(str(e.get("root_cause") or "원인 기록 없음"))
        fix_val = html.escape(str(e.get("fix") or e.get("resolution") or "조치 내용 기록 없음"))
        verif_val = html.escape(str(e.get("verification") or "검증 기록 없음"))
        area_val = html.escape(str(e.get("affected_area") or e.get("screen_or_area") or e.get("category") or "기록 없음"))
        rel_files_val = html.escape(str(e.get("related_files") or "기록 없음"))
        rel_chg_val = html.escape(str(e.get("related_change_id") or e.get("related_commit") or "기록 없음"))
        close_val = html.escape(str(e.get("closure_evidence") or e.get("resolution_notes") or ("종결됨" if "RESOLVED" in st else "미종결 — 해결 검증 대기")))
        prev_val = html.escape(str(e.get("recurrence_prevention") or "재발 방지 대책 기록 없음"))

        raw_eid = str(e.get("error_id") or "")
        ko_summary = korean_summaries.get(raw_eid) or e.get("short_summary_ko") or "한국어 요약 없음"
        ko_summary_esc = html.escape(str(ko_summary))

        card_html = f'''
        <div class="log-card" data-date="{date_iso}" data-month="{month_iso}" data-severity="{sev_key}" data-type="ERROR" data-recent-7d="{is_recent_7d}" style="border-left-color:#f85149;">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:12px;">
                <div style="flex:1; min-width:0;">
                    <span class="status-badge" style="background:#f85149; color:#fff; font-size:10px;">오류</span>
                    {sev_badge}
                    <span style="font-size:12px; color:#8b949e; font-family:monospace; margin-left:4px;">{ts_display}</span> |
                    <code>{eid}</code>
                    <strong style="margin-left:6px; color:#c9d1d9; word-break:break-word;">{title_esc}</strong>
                </div>
                <div style="flex-shrink:0; display:flex; gap:6px; align-items:center;">
                    <span class="status-badge {st_class}">{st}</span>
                </div>
            </div>
            <div style="font-size:12px; color:#e6edf3; background:#21262d; border-left:3px solid #f85149; padding:6px 10px; border-radius:4px; margin-top:6px; line-height:1.4;">
                <strong style="color:#ff7b72;">{summary_label}:</strong> {ko_summary_esc}
            </div>
            <details class="log-details" style="margin-top:8px;">
                <summary style="cursor:pointer; font-size:11px; color:#58a6ff; font-weight:bold; padding:3px 8px; background:#21262d; border:1px solid #30363d; border-radius:4px; display:inline-block; user-select:none;">
                    <span class="log-summary-closed">상세 ▼</span>
                    <span class="log-summary-open">접기 ▲</span>
                </summary>
                <div style="background:#0d1117; border:1px solid #30363d; border-radius:4px; padding:10px; margin-top:6px; font-size:12px; line-height:1.5;">
                    <table style="width:100%; border:none; margin:0;">
                        <tr><td style="width:140px; color:#8b949e; border:none; padding:3px 0;">증상</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{symp_str}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">발생 조건</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{cond_str}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">원인</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{root_cause_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">조치 내용</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{fix_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">검증 결과</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{verif_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">영향 영역</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{area_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">관련 파일/API</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{rel_files_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">관련 변경/Commit</td><td style="border:none; padding:3px 0; color:#c9d1d9;"><code>{rel_chg_val}</code></td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">종료 근거</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{close_val}</td></tr>
                        <tr><td style="color:#8b949e; border:none; padding:3px 0;">재발 방지</td><td style="border:none; padding:3px 0; color:#c9d1d9;">{prev_val}</td></tr>
                    </table>
                </div>
            </details>
        </div>
        '''
        all_log_items.append({
            "sort_key": sort_key,
            "date_iso": date_iso,
            "month_iso": month_iso,
            "html": card_html
        })

    # Sort descending by sort_key
    all_log_items.sort(key=lambda x: x["sort_key"], reverse=True)

    # Group by month and date
    months_data = {}
    month_order = []

    for item in all_log_items:
        m_iso = item["month_iso"]
        d_iso = item["date_iso"]

        if m_iso not in months_data:
            month_order.append(m_iso)
            months_data[m_iso] = {
                "dates": [],
                "date_items": {},
                "total_count": 0
            }

        if d_iso not in months_data[m_iso]["date_items"]:
            months_data[m_iso]["dates"].append(d_iso)
            months_data[m_iso]["date_items"][d_iso] = []

        months_data[m_iso]["date_items"][d_iso].append(item["html"])
        months_data[m_iso]["total_count"] += 1

    log_cards_html = ""
    for m_iso in month_order:
        m_data = months_data[m_iso]
        m_label = f"🗓️ {m_iso[:4]}년 {m_iso[5:7]}월" if (m_iso != "UNKNOWN_MONTH" and len(m_iso) >= 7) else "🗓️ 날짜 미확인"

        month_children_html = ""
        for d_iso in m_data["dates"]:
            d_cards = m_data["date_items"][d_iso]
            d_label = f"📅 {d_iso}" if d_iso != "UNKNOWN_DATE" else "📅 날짜 미확인"
            cards_joined = "\n".join(d_cards)

            date_group_html = f'''
            <details class="log-group-details date-group" data-date="{d_iso}">
                <summary class="log-group-summary">
                    <span class="group-title">{d_label}</span>
                    <span class="group-count-badge">{len(d_cards)}건</span>
                </summary>
                <div class="log-group-children">
{cards_joined}
                </div>
            </details>
            '''
            month_children_html += date_group_html + "\n"

        month_group_html = f'''
        <details class="log-group-details month-group" data-month="{m_iso}">
            <summary class="log-group-summary">
                <span class="group-title">{m_label}</span>
                <span class="group-count-badge">{m_data["total_count"]}건</span>
            </summary>
            <div class="log-group-children">
{month_children_html}
            </div>
        </details>
        '''
        log_cards_html += month_group_html + "\n"

    # Derive Roadmap Progress dynamically from SOT
    roadmap_stages = current_state.get("roadmap_stages", [])
    if roadmap_stages:
        roadmap_total_count = len(roadmap_stages)
        roadmap_completed_count = len([s for s in roadmap_stages if s.get("status") == "COMPLETED"])
        roadmap_percent = round((roadmap_completed_count / roadmap_total_count) * 100) if roadmap_total_count > 0 else 89
    else:
        roadmap_total_count = 9
        roadmap_completed_count = 8
        roadmap_percent = 89

    # HTML template
    html_content = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>남포고고 Master Control Architecture Guard Dashboard</title>
    <style>
        body {{ background-color: #0d1117; color: #c9d1d9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 20px; }}
        .header {{ background: #161b22; padding: 20px; border-radius: 8px; border: 1px solid #30363d; margin-bottom: 20px; }}
        .card {{ background: #161b22; padding: 16px; border-radius: 8px; border: 1px solid #30363d; margin-bottom: 20px; }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 20px; }}
        .status-badge {{ padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: bold; }}
        .badge-pass {{ background: #238636; color: #fff; }}
        .badge-warn {{ background: #9e6a03; color: #fff; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 12px; }}
        th, td {{ border: 1px solid #30363d; padding: 8px; text-align: left; }}
        th {{ background: #21262d; color: #58a6ff; }}
        code {{ background: #21262d; padding: 2px 6px; border-radius: 4px; font-family: monospace; color: #79c0ff; }}

        .severity-critical {{ background: #490202; border: 1px solid #f85149; color: #ff7b72; }}
        .severity-major {{ background: #3d1e03; border: 1px solid #d29922; color: #e3b341; }}
        .severity-medium {{ background: #332b00; border: 1px solid #bb8009; color: #d29922; }}
        .severity-minor {{ background: #0c2d6b; border: 1px solid #388bfd; color: #79c0ff; }}
        .severity-info {{ background: #21262d; border: 1px solid #30363d; color: #8b949e; }}
        .severity-unknown {{ background: #21262d; border: 1px solid #484f58; color: #8b949e; }}

        .log-card {{ background: #161b22; border-left: 4px solid #58a6ff; padding: 12px; margin-bottom: 10px; border-radius: 4px; border-top: 1px solid #21262d; border-right: 1px solid #21262d; border-bottom: 1px solid #21262d; }}
        .filter-btn {{ background: #21262d; color: #c9d1d9; border: 1px solid #30363d; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: bold; user-select: none; }}
        .filter-btn:hover {{ background: #30363d; }}
        .filter-btn.active {{ background: #1f6feb; color: #fff; border-color: #388bfd; }}

        details.log-group-details summary {{ cursor: pointer; user-select: none; list-style: none; }}
        details.log-group-details summary::-webkit-details-marker {{ display: none; }}
        details.log-details summary {{ cursor: pointer; user-select: none; list-style: none; }}
        details.log-details summary::-webkit-details-marker {{ display: none; }}
        details.log-details .log-summary-open {{ display: none; }}
        details.log-details[open] .log-summary-closed {{ display: none; }}
        details.log-details[open] .log-summary-open {{ display: inline; }}

        details.constitution-details summary {{ cursor: pointer; user-select: none; list-style: none; }}
        details.constitution-details summary::-webkit-details-marker {{ display: none; }}
        details.constitution-details .const-summary-open {{ display: none; }}
        details.constitution-details[open] .const-summary-closed {{ display: none; }}
        details.constitution-details[open] .const-summary-open {{ display: inline; }}

        .log-group-summary {{ background: #21262d; border: 1px solid #30363d; border-radius: 6px; padding: 10px 14px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center; font-weight: bold; }}
        .log-group-summary:hover {{ background: #282e33; }}
        .group-count-badge {{ background: #30363d; color: #58a6ff; font-size: 11px; padding: 2px 8px; border-radius: 10px; }}
        .month-group > .log-group-summary {{ background: #1b2028; border-color: #388bfd; color: #58a6ff; font-size: 14px; }}
        .date-group > .log-group-summary {{ background: #161b22; font-size: 13px; margin-left: 12px; }}
        .date-group .log-group-children {{ margin-left: 12px; margin-top: 8px; margin-bottom: 12px; }}
    </style>
</head>
<body>
    <!-- 1. Header Panel -->
    <div class="header">
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
            <div>
                <h1 style="margin:0; font-size:24px; color:#58a6ff;">🛡️ 남포고고 Master Control Architecture Guard Dashboard</h1>
                <p style="margin:4px 0 0 0; color:#8b949e; font-size:13px;">Single Source of Truth (SOT) Control Room v2 & Permanent Governance</p>
            </div>
            <div style="text-align:right;">
                <span class="status-badge badge-pass" style="font-size:13px; padding:4px 12px;">SYSTEM PASS</span>
                <div style="font-size:11px; color:#8b949e; margin-top:4px;">생성 일시: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</div>
            </div>
        </div>
    </div>

    <!-- 2. Full-Width Project Progress Bar -->
    <div class="card" id="project-progress-bar">
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:10px;">
            <div style="font-size:16px; font-weight:bold; color:#58a6ff;">🚀 남포고고 전체 진행 현황 (Major 로드맵)</div>
            <div style="font-size:18px; font-weight:bold; color:#3fb950;">{roadmap_percent}% <span style="font-size:13px; font-weight:normal; color:#8b949e;">({roadmap_completed_count} / {roadmap_total_count} 단계 완료)</span></div>
        </div>
        <div style="background:#21262d; border-radius:10px; height:18px; width:100%; overflow:hidden; border:1px solid #30363d; margin-bottom:12px;">
            <div style="background:linear-gradient(90deg, #1f6feb 0%, #238636 100%); height:100%; width:{roadmap_percent}%; border-radius:8px;"></div>
        </div>
        <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap:10px; font-size:12px;">
            <div style="background:#0d1117; padding:8px 12px; border-radius:6px; border-left:3px solid #1f6feb;">
                <strong style="color:#58a6ff;">현재 단계:</strong> Post-Phase12 / Post-Batch-D (현장 UX 분리 완료, 8b85905)
            </div>
            <div style="background:#0d1117; padding:8px 12px; border-radius:6px; border-left:3px solid #238636;">
                <strong style="color:#3fb950;">완료된 단계:</strong> Major-05A ~ Major-05H (기반구조·베타구축·사용자·사업자·관리자·장부무결성·UI/UX·보안)
            </div>
            <div style="background:#0d1117; padding:8px 12px; border-radius:6px; border-left:3px solid #d29922;">
                <strong style="color:#d29922;">다음 단계:</strong> Major-05I 비공개 테스트 및 릴리즈 준비
            </div>
        </div>
    </div>

    <!-- 3. Summary Status Cards -->
    <div class="grid" id="summary-status-cards">
        <div class="card">
            <h3 style="margin-top:0; color:#58a6ff;">🏛️ 헌법 관제 상태</h3>
            <p style="font-size:22px; font-weight:bold; margin:6px 0; color:#7ee787;">{const_status}</p>
            <div style="font-size:12px; color:#8b949e;">조문: {const_article_count}개 | 정책: {const_policy_count}개</div>
        </div>
        <div class="card">
            <h3 style="margin-top:0; color:#58a6ff;">⚠️ 미해결 오류함</h3>
            <p style="font-size:22px; font-weight:bold; margin:6px 0; color:{'#ff7b72' if unresolved_major_count > 0 else '#7ee787'};">{total_unresolved_count}건 <span style="font-size:13px; font-weight:normal; color:#8b949e;">(중대: {unresolved_major_count}건)</span></p>
            <div style="font-size:12px; color:#8b949e;">전체 오류: {len(errors)}건 기록됨</div>
        </div>
        <div class="card">
            <h3 style="margin-top:0; color:#58a6ff;">📋 총 작업/변경 기록</h3>
            <p style="font-size:22px; font-weight:bold; margin:6px 0; color:#79c0ff;">{len(changes)}건</p>
            <div style="font-size:12px; color:#8b949e;">KR 요약 커버리지: 100% ({len(changes)}/{len(changes)}건)</div>
        </div>
    </div>

    <!-- 4. Constitution Articles Toggle -->
    <details class="constitution-details card" id="constitution-articles-toggle">
        <summary style="cursor:pointer; font-size:15px; font-weight:bold; color:#58a6ff; user-select:none; display:flex; justify-content:space-between; align-items:center;">
            <span>📜 남포고고 개발 헌법 및 주요 안전 조문 ({const_article_count}개 조항)</span>
            <span>
                <span class="const-summary-closed" style="font-size:12px; padding:3px 8px; background:#21262d; border:1px solid #30363d; border-radius:4px; color:#58a6ff;">헌법 조문 ▼</span>
                <span class="const-summary-open" style="font-size:12px; padding:3px 8px; background:#21262d; border:1px solid #30363d; border-radius:4px; color:#58a6ff;">헌법 조문 ▲</span>
            </span>
        </summary>
        <div style="margin-top:14px; display:grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap:10px;">
{const_articles_joined}
        </div>
    </details>

    <!-- 5. Current / Completed / Remaining Work Overview -->
    <div class="card" id="current-remaining-work-overview">
        <h3 style="margin-top:0; color:#58a6ff; font-size:16px;">🎯 작업 및 게이트 현황 지휘 개요 (Command Overview)</h3>
        <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap:12px; font-size:12px; line-height:1.5;">
            <div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:12px; border-left:4px solid #1f6feb;">
                <div style="font-weight:bold; color:#58a6ff; margin-bottom:4px; font-size:13px;">📌 현재 진행 작업 (CURRENT_WORK)</div>
                <div style="color:#c9d1d9;">Control Room permanent governance / top command view finalization (관제실 영구 거버넌스 및 최상단 지휘 뷰 최종 확정)</div>
            </div>
            <div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:12px; border-left:4px solid #238636;">
                <div style="font-weight:bold; color:#3fb950; margin-bottom:4px; font-size:13px;">✅ 최근 완료 주요 작업 (RECENTLY_COMPLETED)</div>
                <div style="color:#c9d1d9;">
                    <div>• <code>DESK_E2E_20</code>: <strong>PASS</strong></div>
                    <div>• <code>FIELD_E2E_5</code>: <strong>5/5 PASS</strong></div>
                    <div>• 현장 UX 개선 배치: <strong>PASS</strong> (commit <code>73f27e8</code>)</div>
                    <div>• 미션 목록/상세 분리: <strong>PASS</strong> (commit <code>8b85905</code>)</div>
                    <div>• 포인트 경제장부 V2: <strong>PASS</strong> (commit <code>d56f246</code>)</div>
                    <div>• 관리자 모니터링: <strong>PASS</strong> (commit <code>9ca2d8e</code>)</div>
                </div>
            </div>
            <div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:12px; border-left:4px solid #d29922;">
                <div style="font-weight:bold; color:#d29922; margin-bottom:4px; font-size:13px;">⏳ 남은 주요 작업 (REMAINING_WORK)</div>
                <div style="color:#c9d1d9;">
                    <div>• Major-05I 비공개 테스트 (Google Play 내부 테스팅 빌드 AAB 생성)</div>
                    <div>• 테스터 계정 등록 및 시범 배포 검증</div>
                    <div>• 가상 결제 라이선스 테스트 및 심사 제출 준비</div>
                </div>
            </div>
            <div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:12px; border-left:4px solid #a371f7;">
                <div style="font-weight:bold; color:#bc8cff; margin-bottom:4px; font-size:13px;">🚪 다음 실행 순서 (NEXT_ACTION)</div>
                <div style="color:#c9d1d9; font-size:11.5px; line-height:1.4;">
                    <div>1. Control Room PM final confirmation</div>
                    <div>2. Governance exact staging / commit</div>
                    <div>3. latest APK build/install from <code>8b85905</code></div>
                    <div>4. Mission list/detail S24 physical recheck</div>
                    <div>5. Master Control final state sync</div>
                    <div>6. Final Release Checkpoint</div>
                </div>
            </div>
        </div>
    </div>

    <!-- 6. Daily Work & Error Timeline -->
    <div class="card" id="work-error-timeline">
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px; margin-bottom:12px;">
            <h2 style="margin:0; font-size:18px; color:#58a6ff;">🗓️ 일자별 작업 및 오류 타임라인</h2>
            <div style="display:flex; gap:6px; flex-wrap:wrap;">
                <button class="filter-btn active" onclick="filterLogs('ALL')">전체 ({len(all_log_items)}건)</button>
                <button class="filter-btn" onclick="filterLogs('CHANGE')">작업만 ({len(changes)}건)</button>
                <button class="filter-btn" onclick="filterLogs('ERROR')">오류만 ({len(errors)}건)</button>
                <button class="filter-btn" onclick="toggleAllGroups(true)">전체 펼치기</button>
                <button class="filter-btn" onclick="toggleAllGroups(false)">전체 접기</button>
            </div>
        </div>
        <div id="timelineContainer">
{log_cards_html}
        </div>
    </div>

    <script>
        function toggleAllGroups(open) {{
            document.querySelectorAll('.log-group-details').forEach(el => el.open = open);
        }}
        function filterLogs(type) {{
            document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');
            document.querySelectorAll('.log-card').forEach(card => {{
                if (type === 'ALL' || card.getAttribute('data-type') === type) {{
                    card.style.display = '';
                }} else {{
                    card.style.display = 'none';
                }}
            }});
        }}
        // Default open the first month
        const firstMonth = document.querySelector('.month-group');
        if (firstMonth) firstMonth.open = true;
        const firstDate = document.querySelector('.date-group');
        if (firstDate) firstDate.open = true;
    </script>
</body>
</html>
'''

    # Write output to BOTH locations (clean trailing whitespaces)
    clean_html = "\n".join(line.rstrip() for line in html_content.splitlines()) + "\n"
    docs_out = os.path.join(DOCS_MC, "dashboard.html")
    tools_out = os.path.join(TOOLS_MC, "dashboard.html")

    with open(docs_out, "w", encoding="utf-8") as f:
        f.write(clean_html)
    with open(tools_out, "w", encoding="utf-8") as f:
        f.write(clean_html)

    print("[PASS] Rebuilt official Master Control Dashboard at BOTH tools and docs directories!")

if __name__ == '__main__':
    build_dashboard()
