const pool = require("../config/db");

async function createAdmin() {
  try {
    const username = process.env.ADMIN_USERNAME;
    const password = process.env.ADMIN_PASSWORD;

    if (!username || !password) {
      console.log("⚠️ Admin credentials are not configured.");
      return;
    }

    const existingAdmin = await pool.query(
      "SELECT id, password FROM users WHERE username = $1",
      [username]
    );

    if (existingAdmin.rows.length > 0) {
      await pool.query(
        `UPDATE users
         SET password = $1,
             role = 'admin'
         WHERE username = $2`,
        [password, username]
      );

      console.log(`✅ Admin '${username}' password synchronized successfully.`);
      return;
    }

    await pool.query(
      `INSERT INTO users (username, password, role)
       VALUES ($1, $2, 'admin')`,
      [username, password]
    );

    console.log(`✅ Admin '${username}' created successfully.`);
  } catch (error) {
    console.error("❌ Failed to create/sync admin:", error.message);
    throw error;
  }
}

module.exports = createAdmin;

