import { Component, OnInit } from '@angular/core';
import { MessagesService } from '../../_services/messages.service';

@Component({
  selector: 'app-messages',
  templateUrl: './messages.component.html',
  styleUrls: ['./messages.component.scss']
})
export class MessagesComponent implements OnInit {

  constructor(
    private messageServ: MessagesService
  ) { }

  ngOnInit() {
  }

}
