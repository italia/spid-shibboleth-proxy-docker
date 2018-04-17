<html>
    <head>
        <title>Who Am I</title>
    </head>
    <body>
        <h1>WhoAmI</h1>

        <h2>Server Environment</h2>
        <pre><?php print_r($_SERVER); ?></pre>

        <h2>Headers</h2>
        <pre>
        <?php
            foreach (getallheaders() as $name => $value) {
                echo "$name: $value\n";
            }
        ?>
        </pre>
    </body>
</html>
