def test_login_success_admin(client, admin_user):
    response = client.post("/auth/login", json={"email": admin_user.email, "password": "correct-password"})

    assert response.status_code == 200
    body = response.json()
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["token_type"] == "bearer"


def test_login_success_employee(client, employee_user):
    response = client.post("/auth/login", json={"email": employee_user.email, "password": "correct-password"})

    assert response.status_code == 200
    assert response.json()["access_token"]


def test_login_wrong_password(client, admin_user):
    response = client.post("/auth/login", json={"email": admin_user.email, "password": "wrong-password"})

    assert response.status_code == 401


def test_login_unknown_email(client):
    response = client.post("/auth/login", json={"email": "nobody@example.com", "password": "whatever"})

    assert response.status_code == 401


def test_me_returns_role_from_token_admin(client, admin_user):
    login_response = client.post(
        "/auth/login", json={"email": admin_user.email, "password": "correct-password"}
    )
    access_token = login_response.json()["access_token"]

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {access_token}"})

    assert response.status_code == 200
    body = response.json()
    assert body["role"] == "admin"
    assert body["email"] == admin_user.email


def test_me_returns_role_from_token_employee(client, employee_user):
    login_response = client.post(
        "/auth/login", json={"email": employee_user.email, "password": "correct-password"}
    )
    access_token = login_response.json()["access_token"]

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {access_token}"})

    assert response.status_code == 200
    assert response.json()["role"] == "employee"


def test_me_without_token_is_unauthorized(client):
    response = client.get("/auth/me")

    assert response.status_code == 401


def test_refresh_issues_new_tokens_and_rotates_old_one(client, admin_user):
    login_response = client.post(
        "/auth/login", json={"email": admin_user.email, "password": "correct-password"}
    )
    old_refresh_token = login_response.json()["refresh_token"]

    refresh_response = client.post("/auth/refresh", json={"refresh_token": old_refresh_token})

    assert refresh_response.status_code == 200
    new_tokens = refresh_response.json()
    assert new_tokens["access_token"]
    assert new_tokens["refresh_token"] != old_refresh_token

    reuse_response = client.post("/auth/refresh", json={"refresh_token": old_refresh_token})
    assert reuse_response.status_code == 401


def test_refresh_with_invalid_token_is_unauthorized(client):
    response = client.post("/auth/refresh", json={"refresh_token": "not-a-real-token"})

    assert response.status_code == 401


def test_logout_revokes_refresh_token(client, admin_user):
    login_response = client.post(
        "/auth/login", json={"email": admin_user.email, "password": "correct-password"}
    )
    refresh_token = login_response.json()["refresh_token"]

    logout_response = client.post("/auth/logout", json={"refresh_token": refresh_token})
    assert logout_response.status_code == 204

    refresh_response = client.post("/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_response.status_code == 401


def test_logout_with_invalid_token_is_unauthorized(client):
    response = client.post("/auth/logout", json={"refresh_token": "not-a-real-token"})

    assert response.status_code == 401


def test_health_endpoint(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
