from app.services.cron_service import explain_cron

def test_explain_cron_macro():
    result = explain_cron("@daily")
    assert result["success"] is True
    assert "daily" in result["description"].lower() or "day" in result["description"].lower()

def test_explain_cron_invalid():
    result = explain_cron("invalid-cron-expr")
    assert result["success"] is False
    assert "error" in result
