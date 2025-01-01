<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Log;

class VideoCallController extends Controller
{
    public function signal(Request $request, $roomId)
    {
        $message = $request->input('message');
        Log::info("Received signaling message for room $roomId: " . json_encode($message));

        Broadcast::channel('video-call.'.$roomId)
            ->broadcast('signaling', ['message' => $message]);

        Log::info("Broadcasted signaling message for room $roomId");

        return response()->json(['status' => 'success']);
    }
}
