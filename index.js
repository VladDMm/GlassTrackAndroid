const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');

// Creare aplicație Express
const app = express();
const port = 8080;

// Configurare Body-Parser pentru a citi corpul cererilor JSON
app.use(bodyParser.json());

// Conectare la baza de date MariaDB
const db = mysql.createConnection({
  host: 'http://mqtt.halley.md:3306',
  user: 'root',  // Schimbă cu utilizatorul tău
  password: 'Halley2025!',  // Schimbă cu parola ta
  database: 'glasstrack_db'  // Schimbă cu numele bazei tale de date
});

db.connect(err => {
  if (err) {
    console.error('Nu am putut să mă conectez la baza de date:', err);
    return;
  }
  console.log('Conectat la baza de date MariaDB');
});

// Endpoint GET pentru a căuta produse
app.get('/api/products', (req, res) => {
  const search = req.query.search || '';  // Obține termenul de căutare din query string
  const sql = `
    SELECT pp.pa_id, a.a_marca_model, ct.cod, c.nume_celula, pp.p_count, pp.p_price
    FROM product_auto_table pp
    JOIN vehicle_table a ON a.a_id = pp.a_id
    JOIN celula_table c ON c.id_celula = pp.celula_id
    JOIN code_table ct ON ct.id_cod = pp.id_cod
    WHERE a.a_marca_model LIKE ? 
       OR ct.cod LIKE ? 
       OR pp.p_price LIKE ? 
       OR pp.p_count LIKE ?
  `;

  db.execute(sql, [`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`], (err, results) => {
    if (err) {
      console.error('Eroare la interogarea bazei de date:', err);
      res.status(500).send('Eroare internă');
      return;
    }
    res.json(results);  // Trimite rezultatele în format JSON
  });
});

// Pornirea serverului
app.listen(port, () => {
  console.log(`API-ul rulează pe http://localhost:${port}`);
});
