<?hh

async function connect(): Awaitable<AsyncMysqlConnection> {
    return ;
}

async function main(): Awaitable<void> {
    $pool = new AsyncMysqlConnectionPool([
        "per_key_connection_limit" => 1000,
        "pool_connection_limit" => 100000,
        "idle_timeout_micros" => 5000000
        "expiration_policy" => "IdleTime",
    ]);
    $db = await $pool->connect('127.0.0.1', 3306, 'loadtesting', 'loadtesting', 'loadtesting');
    $dbq = await $db->query('SELECT HEX(hexId), incrementValue, textField FROM `table1`');

    $data = [];
    while ($dbd = $dbq->fetch_assoc()) {
        $data[] = $dbd;
    }

    echo json_encode($data);
}

\HH\Asio\join(main());
