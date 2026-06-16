from cron_descriptor import get_description

CRON_MACROS = {
    "@yearly": "0 0 1 1 *",
    "@annually": "0 0 1 1 *",
    "@monthly": "0 0 1 * *",
    "@weekly": "0 0 * * 0",
    "@daily": "0 0 * * *",
    "@midnight": "0 0 * * *",
    "@hourly": "0 * * * *",
}

def explain_cron(expression: str) -> dict:
    try:
        clean_expr = expression.strip()
        if not clean_expr:
            return {"success": False, "error": "Empty input", "expression": expression}

        lower_expr = clean_expr.lower()

        # Handle reboot macro directly
        if lower_expr == "@reboot":
            return {
                "success": True, 
                "description": "Runs once at system startup.", 
                "expression": expression
            }

        # Resolve other macros
        target_expr = CRON_MACROS.get(lower_expr, clean_expr)

        description = get_description(target_expr)
        return {"success": True, "description": description, "expression": expression}
    except Exception as e:
        return {"success": False, "error": str(e), "expression": expression}
