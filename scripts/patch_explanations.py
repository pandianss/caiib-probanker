import os
import django
import sys

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Bite

EXPLANATION_PATCH = {
    "abfm_c1_001": "The five core functions—Planning, Organising, Staffing, Directing, and Controlling—represent the traditional management process first conceptualized by Henri Fayol.",
    "abfm_c1_002": "Theory X assumes employees are naturally unmotivated and dislike work, leading to a management style that relies on close supervision and control.",
    "abfm_c1_003": "Theory Y assumes employees are self-motivated, seek responsibility, and find work natural, encouraging a participative management style.",
    "abfm_c1_004": "The 'Scalar Chain' refers to the formal line of authority from highest to lowest ranks, ensuring clear communication and hierarchical reporting.",
    "abfm_c1_005": "Maslow's Hierarchy of Needs ranks human requirements from basic physiological needs to the highest level: Self-Actualization.",
    "abfm_c1_006": "Unity of Command dictates that an employee should receive orders from only one superior to avoid conflicting instructions and confusion.",
    "abfm_c1_007": "Market or Result-oriented culture prioritizes external competition, market share, and achieving measurable financial goals above all else.",
    "abfm_c1_008": "The 'Refreeze' stage stabilizes the organization after change, locking in new behaviors and norms to ensure they become the standard practice.",
    "abfm_c1_009": "In the SECI model, 'Internalization' involves converting explicit knowledge (manuals, documents) into tacit knowledge (personal skills, intuition).",
    "abfm_c1_010": "BARS (Behaviourally Anchored Rating Scales) combines traditional numerical ratings with specific behavioral examples to provide objective performance measurement.",
    "abfm_c1_011": "Transactional leadership focuses on routine, oversight, and a system of rewards (incentives) or punishments (admonitions) to maintain status quo.",
    "abfm_c1_012": "Instrumentality is the belief that successful performance will actually lead to the promised reward or outcome.",
    "abfm_c1_013": "Concurrent control (or steering control) involves monitoring activities in real-time as they occur to correct deviations immediately.",
    "abfm_c1_014": "The Critical Path is the longest sequence of tasks in a project; any delay in these tasks directly delays the total project completion time.",
    "abfm_c1_015": "A 'Strategy' is a broad, long-term approach to achieving goals, whereas a 'Plan' is a specific, often less flexible roadmap for execution.",
    "abfm_c1_016": "SWOT analysis evaluates Internal (Strengths/Weaknesses) and External (Opportunities/Threats) factors to inform strategic decision-making.",
    "abfm_c1_017": "Herzberg's Two-Factor Theory distinguishes between Motivators (which create satisfaction) and Hygiene factors (which prevent dissatisfaction but don't motivate).",
    "abfm_c1_018": "Span of Control refers to the number of subordinates that a manager can effectively supervise; it can be 'wide' (many) or 'narrow' (few).",
    "abfm_c1_019": "Laissez-faire leadership is a 'hands-off' approach where leadres provide minimal guidance and let team members make most decisions.",
    "abfm_c1_020": "A Matrix Structure involves dual reporting lines—usually to both a functional manager and a project/product manager.",
    "abfm_c1_021": "Vertical Integration occurs when a company acquires its suppliers (backward) or its distributors (forward) to control more of the value chain.",
    "abfm_c1_022": "Corporate Social Responsibility (CSR) is the practice of integrating social and environmental concerns into business operations and interactions.",
    "abfm_c1_023": "Balance Scorecard perspectives include: Financial, Customer, Internal Process, and Learning & Growth.",
    "abfm_c1_024": "KPIs (Key Performance Indicators) are quantifiable metrics used to evaluate the success of an organization in reaching targets.",
    "abfm_c1_025": "Benchmarking is the process of comparing one's business processes and performance metrics to industry bests or best practices from other companies.",
    "abfm_c1_026": "Kaizen is a Japanese philosophy focusing on continuous, incremental improvement involving all employees from top management to workers.",
    "abfm_c1_027": "Six Sigma is a set of techniques for process improvement aimed at reducing defects to near-zero (3.4 per million opportunities).",
    "abfm_c1_028": "Total Quality Management (TQM) is an organization-wide effort to install and make permanent a climate where it continuously improves its ability to deliver high-quality products.",
    "abfm_c1_029": "A learning organization (Peter Senge) is one that facilitates the learning of its members and continuously transforms itself.",
    "abfm_c1_030": "ADKAR stands for Awareness, Desire, Knowledge, Ability, and Reinforcement—a goal-oriented change management model that guides individual and organizational change.",
    "abfm_c1_031": "The five stages of emotional response to change (Kübler-Ross) are Denial, Anger, Bargaining, Depression, and Acceptance.",
    "abfm_c1_032": "Ignoring conflict allows it to escalate, damaging team morale, productivity, and organizational health. Early intervention is critical for healthy resolution.",
    "abfm_c1_033": "Contingency recruiting (or 'no win, no fee') only rewards the recruiter when a candidate they provide is successfully hired by the client.",
    "abfm_c1_034": "Workplace diversity brings broader perspectives, improves innovation, enhances problem-solving, and better reflects a global customer base.",
    "abfm_c1_035": "Alderfer's ERG Theory identifies three core needs: Existence (basic material requirements), Relatedness (interpersonal relationships), and Growth (personal development).",
    "abfm_c1_036": "Equity Theory suggests that employees compare their own input/outcome ratio with that of others to determine if they are being treated fairly.",
    "abfm_c1_037": "Intrapersonal communication is the internal dialogue or 'self-talk' that takes place within an individual's own mind.",
    "abfm_c1_038": "IT General Controls (ITGC) apply to all systems (e.g., access, backup), while Application Controls are specific to individual business processes (e.g., data validation).",
    "abfm_c1_039": "The COSO Internal Control framework consists of five components: Control Environment, Risk Assessment, Control Activities, Information & Communication, and Monitoring.",
}

def patch_missing_explanations():
    print("Starting content patch for missing explanations...")
    updated_count = 0
    
    for bite_id, explanation in EXPLANATION_PATCH.items():
        try:
            bite = Bite.objects.get(bite_id=bite_id)
            if not bite.explanation or bite.explanation.strip() == "":
                bite.explanation = explanation
                bite.save()
                updated_count += 1
                print(f"Patched: {bite_id}")
        except Bite.DoesNotExist:
            print(f"Skipping: {bite_id} (not found in DB)")

    print(f"Patching complete. Total updated: {updated_count}")

if __name__ == "__main__":
    patch_missing_explanations()
