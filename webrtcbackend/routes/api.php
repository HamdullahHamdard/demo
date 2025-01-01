<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\VideoCallController;

Route::post('/video-call/{roomId}/signal', [VideoCallController::class, 'signal']);

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
