#!/usr/bin/env python3
"""
classroom_sync.py — Google Classroom API Integration for the Alim Agent

This module handles:
  - OAuth2 authentication with Google Classroom API
  - Fetching courses, announcements, assignments, and materials
  - Storing synced data in the knowledge base
  - Checking for upcoming due dates
  - Logging sync operations

Usage:
  python classroom_sync.py --auth              # Run OAuth2 flow
  python classroom_sync.py --sync all          # Full sync
  python classroom_sync.py --sync courses      # Sync courses only
  python classroom_sync.py --sync announcements # Sync announcements
  python classroom_sync.py --sync assignments  # Sync assignments
  python classroom_sync.py --check-due         # Check upcoming due dates
  python classroom_sync.py --status            # Show last sync status

Requirements:
  pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
"""

import argparse
import json
import logging
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[3]  # project root
CONFIG_FILE = BASE_DIR / "config.yaml"
CREDENTIALS_FILE = BASE_DIR / "google_credentials.json"
TOKEN_FILE = BASE_DIR / "google_token.json"
KNOWLEDGE_DIR = BASE_DIR / "knowledge" / "_classroom"
SYNC_LOG_FILE = KNOWLEDGE_DIR / "_sync_log.json"

# Google Classroom API scopes
SCOPES = [
    "https://www.googleapis.com/auth/classroom.courses.readonly",
    "https://www.googleapis.com/auth/classroom.announcements.readonly",
    "https://www.googleapis.com/auth/classroom.coursework.students.readonly",
    "https://www.googleapis.com/auth/classroom.courseworkmaterials.readonly",
]

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("classroom_sync")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_config() -> dict:
    """Load config.yaml and return as dict."""
    try:
        import yaml
        with open(CONFIG_FILE, "r") as f:
            return yaml.safe_load(f) or {}
    except FileNotFoundError:
        logger.warning("config.yaml not found; using defaults.")
        return {}
    except ImportError:
        logger.warning("PyYAML not installed; using defaults.")
        return {}


def ensure_dirs():
    """Create knowledge directories if they don't exist."""
    KNOWLEDGE_DIR.mkdir(parents=True, exist_ok=True)


def load_json(path: Path) -> dict | list | None:
    """Safely load a JSON file."""
    if path.exists():
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            logger.warning(f"Could not load {path}: {e}")
    return None


def save_json(path: Path, data):
    """Safely save data to a JSON file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False, default=str)
    logger.info(f"Saved: {path}")


def update_sync_log(operation: str, status: str, details: str = ""):
    """Append an entry to the sync log."""
    log = load_json(SYNC_LOG_FILE) or []
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "operation": operation,
        "status": status,
        "details": details,
    }
    log.append(entry)
    # Keep last 500 entries
    log = log[-500:]
    save_json(SYNC_LOG_FILE, log)


def format_due_date(due_date: dict, due_time: dict = None) -> str | None:
    """Format a Google Classroom due date into a readable string."""
    if not due_date:
        return None
    try:
        year = due_date.get("year", 2000)
        month = due_date.get("month", 1)
        day = due_date.get("day", 1)
        date_str = f"{year}-{month:02d}-{day:02d}"
        if due_time:
            hours = due_time.get("hours", 0)
            minutes = due_time.get("minutes", 0)
            date_str += f" {hours:02d}:{minutes:02d}"
        return date_str
    except (TypeError, ValueError):
        return None


def days_until_due(due_date: dict) -> int | None:
    """Calculate days until a due date. Returns None if no due date."""
    if not due_date:
        return None
    try:
        year = due_date.get("year", 2000)
        month = due_date.get("month", 1)
        day = due_date.get("day", 1)
        due = datetime(year, month, day, tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        return (due - now).days
    except (TypeError, ValueError):
        return None


# ---------------------------------------------------------------------------
# Google API Authentication
# ---------------------------------------------------------------------------

def get_classroom_service():
    """
    Authenticate and return a Google Classroom API service object.
    Uses OAuth2 flow with stored token.
    """
    try:
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except ImportError:
        logger.error(
            "Google API libraries not installed. Run:\n"
            "  pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib"
        )
        sys.exit(1)

    creds = None

    # Load existing token
    if TOKEN_FILE.exists():
        try:
            creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
            logger.info("Loaded existing token.")
        except Exception as e:
            logger.warning(f"Could not load token: {e}")

    # Refresh or create new credentials
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
                logger.info("Refreshed expired token.")
            except Exception as e:
                logger.warning(f"Could not refresh token: {e}")
                creds = None

        if not creds:
            if not CREDENTIALS_FILE.exists():
                logger.error(
                    f"Credentials file not found: {CREDENTIALS_FILE}\n"
                    "Download it from Google Cloud Console:\n"
                    "  1. Go to https://console.cloud.google.com/\n"
                    "  2. Enable Google Classroom API\n"
                    "  3. Create OAuth 2.0 Desktop credentials\n"
                    "  4. Download JSON and save as google_credentials.json"
                )
                sys.exit(1)

            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES
            )
            creds = flow.run_local_server(port=0)
            logger.info("Completed OAuth2 flow.")

        # Save token for next time
        save_json(TOKEN_FILE, json.loads(creds.to_json()))

    service = build("classroom", "v1", credentials=creds)
    logger.info("Google Classroom API service created.")
    return service


# ---------------------------------------------------------------------------
# Sync Operations
# ---------------------------------------------------------------------------

def sync_courses(service) -> list:
    """Fetch all active courses."""
    logger.info("Syncing courses...")
    courses = []
    page_token = None

    try:
        while True:
            results = service.courses().list(
                pageSize=100,
                pageToken=page_token,
                courseStates=["ACTIVE"],
            ).execute()
            courses.extend(results.get("courses", []))
            page_token = results.get("nextPageToken")
            if not page_token:
                break

        # Simplify course data
        simplified = []
        for c in courses:
            simplified.append({
                "id": c.get("id"),
                "name": c.get("name"),
                "section": c.get("section", ""),
                "description": c.get("descriptionHeading", ""),
                "room": c.get("room", ""),
                "ownerId": c.get("ownerId"),
                "creationTime": c.get("creationTime"),
                "updateTime": c.get("updateTime"),
                "alternateLink": c.get("alternateLink"),
                "courseGroupEmail": c.get("courseGroupEmail"),
                "teacherGroupEmail": c.get("teacherGroupEmail"),
                "calendarId": c.get("calendarId"),
            })

        save_json(KNOWLEDGE_DIR / "courses.json", simplified)
        logger.info(f"Synced {len(simplified)} courses.")
        update_sync_log("sync_courses", "success", f"{len(simplified)} courses")
        return simplified

    except Exception as e:
        logger.error(f"Failed to sync courses: {e}")
        update_sync_log("sync_courses", "error", str(e))
        return []


def sync_announcements(service, courses: list):
    """Fetch announcements for each course."""
    logger.info("Syncing announcements...")
    total = 0

    for course in courses:
        course_id = course["id"]
        course_name = course.get("name", "Unknown")
        try:
            announcements = []
            page_token = None
            while True:
                results = service.courses().announcements().list(
                    courseId=course_id,
                    pageSize=100,
                    pageToken=page_token,
                ).execute()
                announcements.extend(results.get("announcements", []))
                page_token = results.get("nextPageToken")
                if not page_token:
                    break

            # Simplify
            simplified = []
            for a in announcements:
                simplified.append({
                    "id": a.get("id"),
                    "text": a.get("text", ""),
                    "materials": a.get("materials", []),
                    "creationTime": a.get("creationTime"),
                    "updateTime": a.get("updateTime"),
                    "state": a.get("state", "PUBLISHED"),
                    "alternateLink": a.get("alternateLink"),
                    "assigneeMode": a.get("assigneeMode"),
                })

            save_json(
                KNOWLEDGE_DIR / course_id / "announcements.json",
                simplified,
            )
            total += len(simplified)
            logger.info(f"  {course_name}: {len(simplified)} announcements")

        except Exception as e:
            logger.warning(f"  {course_name}: Error syncing announcements: {e}")

    update_sync_log("sync_announcements", "success", f"{total} total announcements")
    logger.info(f"Total announcements synced: {total}")


def sync_assignments(service, courses: list):
    """Fetch coursework (assignments) for each course."""
    logger.info("Syncing assignments...")
    total = 0

    for course in courses:
        course_id = course["id"]
        course_name = course.get("name", "Unknown")
        try:
            assignments = []
            page_token = None
            while True:
                results = service.courses().courseWork().list(
                    courseId=course_id,
                    pageSize=100,
                    pageToken=page_token,
                ).execute()
                assignments.extend(results.get("courseWork", []))
                page_token = results.get("nextPageToken")
                if not page_token:
                    break

            # Simplify
            simplified = []
            for a in assignments:
                due = format_due_date(
                    a.get("dueDate"), a.get("dueTime")
                )
                days_left = days_until_due(a.get("dueDate"))
                simplified.append({
                    "id": a.get("id"),
                    "title": a.get("title", ""),
                    "description": a.get("description", ""),
                    "materials": a.get("materials", []),
                    "state": a.get("state", "PUBLISHED"),
                    "alternateLink": a.get("alternateLink"),
                    "creationTime": a.get("creationTime"),
                    "updateTime": a.get("updateTime"),
                    "dueDate": due,
                    "daysUntilDue": days_left,
                    "maxPoints": a.get("maxPoints"),
                    "workType": a.get("workType"),
                    "assignment": a.get("assignment"),
                    "multipleChoiceQuestion": a.get("multipleChoiceQuestion"),
                })

            save_json(
                KNOWLEDGE_DIR / course_id / "assignments.json",
                simplified,
            )
            total += len(simplified)
            logger.info(f"  {course_name}: {len(simplified)} assignments")

        except Exception as e:
            logger.warning(f"  {course_name}: Error syncing assignments: {e}")

    update_sync_log("sync_assignments", "success", f"{total} total assignments")
    logger.info(f"Total assignments synced: {total}")


def sync_materials(service, courses: list):
    """Fetch course materials for each course."""
    logger.info("Syncing course materials...")
    total = 0

    for course in courses:
        course_id = course["id"]
        course_name = course.get("name", "Unknown")
        try:
            materials = []
            page_token = None
            while True:
                results = service.courses().courseWorkMaterials().list(
                    courseId=course_id,
                    pageSize=100,
                    pageToken=page_token,
                ).execute()
                materials.extend(results.get("courseWorkMaterials", []))
                page_token = results.get("nextPageToken")
                if not page_token:
                    break

            # Simplify
            simplified = []
            for m in materials:
                simplified.append({
                    "id": m.get("id"),
                    "title": m.get("title", ""),
                    "description": m.get("description", ""),
                    "materials": m.get("materials", []),
                    "state": m.get("state", "PUBLISHED"),
                    "alternateLink": m.get("alternateLink"),
                    "creationTime": m.get("creationTime"),
                    "updateTime": m.get("updateTime"),
                    "assigneeMode": m.get("assigneeMode"),
                    "topicId": m.get("topicId"),
                })

            save_json(
                KNOWLEDGE_DIR / course_id / "materials.json",
                simplified,
            )
            total += len(simplified)
            logger.info(f"  {course_name}: {len(simplified)} materials")

        except Exception as e:
            logger.warning(f"  {course_name}: Error syncing materials: {e}")

    update_sync_log("sync_materials", "success", f"{total} total materials")
    logger.info(f"Total materials synced: {total}")


# ---------------------------------------------------------------------------
# Due Date Checker
# ---------------------------------------------------------------------------

def check_due_dates():
    """Check for upcoming due dates and print reminders."""
    logger.info("Checking upcoming due dates...")

    courses = load_json(KNOWLEDGE_DIR / "courses.json") or []
    if not courses:
        logger.warning("No courses found. Run --sync first.")
        return

    now = datetime.now(timezone.utc)
    upcoming = []
    overdue = []

    for course in courses:
        course_id = course["id"]
        course_name = course.get("name", "Unknown")
        assignments = load_json(
            KNOWLEDGE_DIR / course_id / "assignments.json"
        ) or []

        for a in assignments:
            days = a.get("daysUntilDue")
            if days is None:
                continue
            entry = {
                "course": course_name,
                "title": a.get("title", "Untitled"),
                "dueDate": a.get("dueDate", "Unknown"),
                "daysUntilDue": days,
                "link": a.get("alternateLink", ""),
            }
            if days < 0:
                overdue.append(entry)
            elif days <= 7:
                upcoming.append(entry)

    # Print report
    print("\n" + "=" * 60)
    print("📚 Alim Agent — Due Date Report")
    print(f"   {now.strftime('%Y-%m-%d %H:%M UTC')}")
    print("=" * 60)

    if overdue:
        print(f"\n⚠️  OVERDUE ({len(overdue)}):")
        for item in sorted(overdue, key=lambda x: x["daysUntilDue"]):
            print(f"   ❌ {item['course']}: {item['title']} "
                  f"(due {item['dueDate']}, {abs(item['daysUntilDue'])} days ago)")

    if upcoming:
        print(f"\n📅 UPCOMING (next 7 days) ({len(upcoming)}):")
        for item in sorted(upcoming, key=lambda x: x["daysUntilDue"]):
            if item["daysUntilDue"] == 0:
                when = "TODAY"
            elif item["daysUntilDue"] == 1:
                when = "tomorrow"
            else:
                when = f"in {item['daysUntilDue']} days"
            print(f"   📝 {item['course']}: {item['title']} "
                  f"(due {item['dueDate']}, {when})")

    if not overdue and not upcoming:
        print("\n✅ No overdue or upcoming assignments in the next 7 days. "
              "Masha'Allah, you're on top of things!")

    print("\n" + "=" * 60)
    update_sync_log("check_due_dates", "success",
                    f"{len(overdue)} overdue, {len(upcoming)} upcoming")


# ---------------------------------------------------------------------------
# Status
# ---------------------------------------------------------------------------

def show_status():
    """Display the last sync status."""
    log = load_json(SYNC_LOG_FILE) or []
    if not log:
        print("No sync history found. Run --sync first.")
        return

    print("\n📊 Alim Agent — Sync Status")
    print("=" * 50)
    for entry in log[-10:]:
        ts = entry.get("timestamp", "Unknown")
        op = entry.get("operation", "Unknown")
        status = entry.get("status", "Unknown")
        details = entry.get("details", "")
        icon = "✅" if status == "success" else "❌"
        print(f"  {icon} {ts} | {op} | {details}")

    # Show course count
    courses = load_json(KNOWLEDGE_DIR / "courses.json") or []
    print(f"\n  📚 Courses tracked: {len(courses)}")
    for c in courses:
        print(f"     • {c.get('name', 'Unknown')}")
    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Google Classroom Sync for the Alim Agent",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python classroom_sync.py --auth              # Authenticate with Google
  python classroom_sync.py --sync all          # Full sync
  python classroom_sync.py --sync courses      # Sync courses only
  python classroom_sync.py --check-due         # Check due dates
  python classroom_sync.py --status            # Show sync status
        """,
    )
    parser.add_argument(
        "--auth", action="store_true",
        help="Run OAuth2 authentication flow",
    )
    parser.add_argument(
        "--sync", choices=["all", "courses", "announcements", "assignments", "materials"],
        help="Sync data from Google Classroom",
    )
    parser.add_argument(
        "--check-due", action="store_true",
        help="Check for upcoming due dates",
    )
    parser.add_argument(
        "--status", action="store_true",
        help="Show last sync status",
    )

    args = parser.parse_args()

    ensure_dirs()

    if args.auth:
        service = get_classroom_service()
        print("✅ Authentication successful! Token saved.")
        update_sync_log("auth", "success", "OAuth2 flow completed")
        return

    if args.sync:
        service = get_classroom_service()
        courses = []

        if args.sync in ("all", "courses"):
            courses = sync_courses(service)

        if args.sync in ("all", "announcements"):
            if not courses:
                courses = load_json(KNOWLEDGE_DIR / "courses.json") or []
            sync_announcements(service, courses)

        if args.sync in ("all", "assignments"):
            if not courses:
                courses = load_json(KNOWLEDGE_DIR / "courses.json") or []
            sync_assignments(service, courses)

        if args.sync in ("all", "materials"):
            if not courses:
                courses = load_json(KNOWLEDGE_DIR / "courses.json") or []
            sync_materials(service, courses)

        print(f"\n✅ Sync complete: {args.sync}")
        return

    if args.check_due:
        check_due_dates()
        return

    if args.status:
        show_status()
        return

    parser.print_help()


if __name__ == "__main__":
    main()
