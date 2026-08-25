@extends('layouts.app')

@section('content')
<div class="container">
  <div class="admin-page-title"><div><p class="admin-eyebrow">Operaciones</p><h1>Ops Readiness</h1><p class="admin-page-subtitle">Consulta rápidamente la salud técnica del backoffice.</p></div></div>
  @include('admin.partials.nav')

  <div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
      <span>Estado operativo</span>
      <a href="{{ route('admin.ops.readiness') }}" class="btn btn-sm btn-outline-primary">Refrescar</a>
    </div>
    <div class="table-responsive">
      <table class="table mb-0">
        <tbody>
          @foreach($readiness as $key => $value)
            <tr>
              <th style="width:320px">{{ $key }}</th>
              <td>
                @if(is_bool($value))
                  {{ $value ? 'true' : 'false' }}
                @elseif(is_array($value))
                  <pre class="mb-0">{{ json_encode($value, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE) }}</pre>
                @else
                  {{ $value ?? 'null' }}
                @endif
              </td>
            </tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>
</div>
@endsection
