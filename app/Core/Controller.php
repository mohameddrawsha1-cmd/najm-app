<?php
declare(strict_types=1);

namespace App\Core;

abstract class Controller
{
    protected function view(string $view, array $data = [], string $layout = 'layouts/app'): void
    {
        View::render($view, $data, $layout);
    }

    protected function input(string $key, mixed $default = null): mixed
    {
        return $_POST[$key] ?? $_GET[$key] ?? $default;
    }

    protected function validate(array $rules): array
    {
        $errors = [];
        foreach ($rules as $field => $ruleSet) {
            $value = trim((string) ($_POST[$field] ?? ''));
            foreach (explode('|', $ruleSet) as $rule) {
                if ($rule === 'required' && $value === '') {
                    $errors[$field] = 'هذا الحقل مطلوب.';
                } elseif ($rule === 'email' && $value !== '' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    $errors[$field] = 'صيغة البريد الإلكتروني غير صحيحة.';
                } elseif (str_starts_with($rule, 'max:') && mb_strlen($value) > (int) substr($rule, 4)) {
                    $errors[$field] = 'القيمة أطول من الحد المسموح.';
                }
            }
        }
        if ($errors) {
            Flash::put('errors', $errors);
            Flash::old(array_diff_key($_POST, ['password' => true, '_token' => true]));
        }
        return $errors;
    }
}
