<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Flash;
use App\Repositories\TicketRepository;
use Throwable;

final class TicketController extends Controller
{
    private TicketRepository $tickets;

    public function __construct()
    {
        $this->tickets = new TicketRepository();
    }

    public function index(): void
    {
        Auth::requireLogin();
        $filters = [
            'q' => trim((string) $this->input('q', '')),
            'status' => trim((string) $this->input('status', '')),
            'priority' => trim((string) $this->input('priority', '')),
        ];
        $this->view('tickets/index', [
            'title' => 'الطلبات',
            'tickets' => $this->tickets->list($filters),
            'options' => $this->tickets->formOptions(),
            'filters' => $filters,
        ]);
    }

    public function create(): void
    {
        Auth::requireLogin();
        $this->view('tickets/create', [
            'title' => 'طلب جديد',
            'options' => $this->tickets->formOptions(),
        ]);
    }

    public function store(): void
    {
        Auth::requireLogin();
        $errors = $this->validate([
            'ticket_kind' => 'required|max:30',
            'title' => 'required|max:220',
            'description' => 'required|max:10000',
            'category_id' => 'required',
            'priority_id' => 'required',
        ]);
        $allowedKinds = ['INCIDENT', 'SERVICE_REQUEST', 'ONBOARDING', 'OFFBOARDING', 'GENERAL_REQUEST'];
        if (!in_array($this->input('ticket_kind'), $allowedKinds, true)) {
            $errors['ticket_kind'] = 'نوع الطلب غير صحيح.';
        }
        if ($errors) {
            Flash::put('errors', $errors);
            redirect('/tickets/create');
        }
        $id = $this->tickets->create([
            'ticket_kind' => (string) $this->input('ticket_kind'),
            'title' => trim((string) $this->input('title')),
            'description' => trim((string) $this->input('description')),
            'category_id' => (int) $this->input('category_id'),
            'priority_id' => (int) $this->input('priority_id'),
            'requester_user_id' => Auth::id(),
            'location_id' => (int) $this->input('location_id'),
            'device_id' => (int) $this->input('device_id'),
        ]);
        Flash::put('success', 'تم إنشاء الطلب بنجاح.');
        redirect('/tickets/' . $id);
    }

    public function show(int $id): void
    {
        Auth::requireLogin();
        $ticket = $this->tickets->find($id);
        if (!$ticket) {
            http_response_code(404);
            $this->view('errors/404', ['title' => 'الطلب غير موجود']);
            return;
        }
        $this->view('tickets/show', [
            'title' => $ticket['ticket_number'],
            'ticket' => $ticket,
            'messages' => $this->tickets->messages($id),
            'history' => $this->tickets->history($id),
            'options' => $this->tickets->formOptions(),
        ]);
    }

    public function message(int $id): void
    {
        Auth::requireLogin();
        $message = trim((string) $this->input('message'));
        if ($message === '') {
            Flash::put('error', 'اكتب الرسالة أولًا.');
            redirect('/tickets/' . $id);
        }
        try {
            $this->tickets->addMessage($id, $message, (bool) $this->input('is_internal', false));
            Flash::put('success', 'تمت إضافة التحديث.');
        } catch (Throwable $exception) {
            Flash::put('error', $exception->getMessage());
        }
        redirect('/tickets/' . $id);
    }

    public function status(int $id): void
    {
        try {
            $this->tickets->updateStatus($id, (int) $this->input('status_id'), trim((string) $this->input('note')));
            Flash::put('success', 'تم تحديث حالة الطلب.');
        } catch (Throwable $exception) {
            Flash::put('error', $exception->getMessage());
        }
        redirect('/tickets/' . $id);
    }

    public function assign(int $id): void
    {
        try {
            $this->tickets->assign($id, (int) $this->input('agent_id'));
            Flash::put('success', 'تم إسناد الطلب.');
        } catch (Throwable $exception) {
            Flash::put('error', $exception->getMessage());
        }
        redirect('/tickets/' . $id);
    }
}
