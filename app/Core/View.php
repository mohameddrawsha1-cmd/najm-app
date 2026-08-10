<?php
declare(strict_types=1);

namespace App\Core;

use RuntimeException;

final class View
{
    public static function render(string $view, array $data = [], string $layout = 'layouts/app'): void
    {
        $viewFile = dirname(__DIR__) . '/Views/' . $view . '.php';
        $layoutFile = dirname(__DIR__) . '/Views/' . $layout . '.php';
        if (!is_file($viewFile) || !is_file($layoutFile)) {
            throw new RuntimeException('ملف العرض غير موجود.');
        }
        extract($data, EXTR_SKIP);
        ob_start();
        require $viewFile;
        $content = (string) ob_get_clean();
        require $layoutFile;
    }
}
